---
title: 小念AI对话实战
description: 小念AI对话实战
category: 全栈
tag:
  - 全栈
---

# 关于小念AI对话

项目地址为：[小念AI对话](http://114.132.72.233)

## 项目概述

这是一个基于Node.js和Express框架开发的AI对话应用，通过OpenAI SDK调用阿里云的通义千问模型(qwen-plus)，实现了完整的对话系统。当前该项目交互不是很好,主要是学习下AI前后端流式交互模式。

## 技术栈

- 前端：Vue3 + vue-element-plus-x + hook-fetch
- 后端：express + knex + mysql2 + openai

## 核心功能

### 1. AI对话功能

- 实现了基于SSE(Server-Sent Events)的流式输出，提升用户体验
- 每日对话次数限制（通过环境变量配置）
- 自动保存对话记录到数据库

### 2. 会话管理

- 创建新会话，生成唯一会话ID
- 获取会话列表
- 支持会话复用机制（空标题会话复用）

### 3. 消息管理

- 获取指定会话的消息列表
- 保存用户和AI的对话记录
- 按时间顺序排序消息

## 核心代码(主要是后端代码)
```javascript
require('dotenv').config();
const express = require('express');
const router = express.Router();
const knex = require('../db'); // 导入 Knex 实例
const { v4: uuidv4 } = require('uuid');
const { OpenAI } = require('openai');

// 创建OpenAI客户端（配置为使用DashScope的Qwen模型）
const openai = new OpenAI({
  apiKey: process.env.DASHSCOPE_API_KEY, //API密钥
  baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
});

/**
 * @description: 对话接口
 * @param {*} message 用户输入的消息内容
 * @param {*} sessionId 会话ID
 */
router.post("/api/chat", async (req, res) => {
  const { message, sessionId } = req.body;
  if (!message || !sessionId) {
    return res.status(200).json({ error: "缺少消息内容或会话ID" });
  }

  // 设置响应头，支持SSE流式输出
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  //保存用户对话记录到数据库
  await knex("t_messages").insert({
    message_id: uuidv4(),  //信息id
    conversation_id: sessionId, // 会话id
    role: "user", // 角色  user/ai
    content: message, // 用户输入的消息内容
    created_at: knex.fn.now(),
  });

  // 系统提示词，引导模型展示思考过程
  const systemPrompt = `你是一个AI助手，在回答用户问题之前，请先展示你的思考过程。
          
思考过程应包含以下步骤：
1. 思考步骤1：分析问题
2. 思考步骤2：确定解决方法
3. 思考步骤3：执行计划
4. 思考步骤4：验证结果

最后，用"最终答案："引出你的答案。`;

  // openai 调用模型，获取流式响应
  const stream = await openai.chat.completions.create({
    model: "qwen-plus",
    messages: [
      {
        role: "system",
        content: systemPrompt,
      },
      { role: "user", content: message },
    ],
    temperature: 0.7,
    max_tokens: 1000,
    stream: true, // 启用流式输出
  });

  // 处理流式响应
  let fullResponse = ""; //记录完整响应内容
  let isResponseFinished = false; //标记响应是否已完成
  let isResponseClosed = false; //标记连接是否已关闭

  // 监听响应完成事件
  res.on("finish", () => {
    isResponseFinished = true;
    console.log("响应已正常完成");
  });
  // 监听前端连接关闭事件
  res.on("close", () => {
    isResponseClosed = true;
    console.log("连接已关闭");
    // // 只有当响应未正常完成时，才存储部分数据
    if (!isResponseFinished && fullResponse.length > 0) {
      // 异步存储部分数据，使用IIFE避免阻塞
      try {
        (async () => {
          await knex("t_messages").insert({
            message_id: uuidv4(),
            conversation_id: sessionId,
            role: "ai",
            content: fullResponse,
            created_at: knex.fn.now(),
          });
        })();
      } catch (dbError) {
        console.error("存储部分响应失败:", dbError);
      }
    }
  });

  // 处理流式响应，将每个chunk的内容发送给前端
  try {
    for await (const chunk of stream) {
      // 检查连接是否已关闭，如果已关闭则中断循环
      if (isResponseFinished || isResponseClosed) {
        break;
      }
      const content = chunk.choices[0]?.delta?.content || "";
      if (content) {
        fullResponse += content;
        // 发送SSE事件
        res.write(`data: ${JSON.stringify({ content, done: false })}\n\n`);
      }
    }
  } catch (error) {
    console.error("流式处理异常:", error);
  }

  // 解析思考过程和最终答案
  const thinkingMatch = fullResponse.match(
    /思考步骤\d+：(.*?)(?=思考步骤\d+：|$)/gs,
  );
  const finalAnswerMatch = fullResponse.match(/最终答案：(.*)/s);

  const thinkingProcess = thinkingMatch
    ? thinkingMatch.map((step) => step.trim())
    : [];
  const finalAnswer = finalAnswerMatch
    ? finalAnswerMatch[1].trim()
    : fullResponse;

  // 发送完成事件，包含完整结构化数据,并修改done状态为true
  res.write(
    `data: ${JSON.stringify({
      content: fullResponse,
      done: true,
      reply: finalAnswer,
      thinkingProcess: thinkingProcess,
    })}\n\n`,
  );

  // 如果连接未关闭，说明流式响应正常完成
  if (!isResponseFinished && !isResponseClosed) {
    await knex("t_messages").insert({
      message_id: uuidv4(),
      conversation_id: sessionId,
      role: "ai",
      content: fullResponse,
      created_at: knex.fn.now(),
    });
  }

  res.end();
});
```

## 问题思考

### 1.systemPrompt 参数的作用?

我的理解是它是用来规范AI输出的,确保AI的回答符合我们的预期.

### 2.设置响应头的作用?

设置响应头的作用是告诉浏览器,服务器返回的是SSE流,浏览器需要按照SSE的格式解析.以及流式输出的作用是实时返回对话内容,提升用户体验.

```JavaScript
//SSE事件流格式,告诉浏览器这是一个需要持续接收的事件流，而不是普通的一次性HTTP响应
res.setHeader("Content-Type", "text/event-stream");
// 告诉浏览器禁止缓存,保证是最新的数据内容
res.setHeader("Cache-Control", "no-cache");
//保持HTTP请求连接持久化,不是响应后立即关闭,维持SSE的基础
res.setHeader("Connection", "keep-alive");
```

### 3.响应时间的完成和关闭事件处理是为了什么?
`finish`事件: **isResponseFinished** 标记响应是否已完成,用户后续ai对话内容防止响应关闭后的数据的重复存储

`close`事件: **isResponseClosed** 标记连接是否已关闭,响应关闭后用来存储已经获取到的AI响应内容存储到数据库


## 后续优化
前端:
- 增加会话名称功能,用户可以自定义会话名称,方便识别不同的对话.
- 增加会话删除功能,用户可以在前端删除不需要的会话.

后端:
- 目前是使用 OpenAI 插件进行AI交互,后续学习使用langchain,langgraph等框架,实现更复杂的对话功能.

设计:
- 目前对话的是没有区分用户的,所以交互上可能会出现使用同个会话导致数据混乱的问题,后续再考虑增加用户认证功能,区分不同用户的对话记录.