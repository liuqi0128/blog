---
title: React 学习
description: 由浅入深的 React 学习笔记：心智模型、Hooks、渲染机制，以及 Router / 状态管理 / Next.js 等生态
category: React
tag:
  - React
  - Hooks
  - TypeScript
  - Next.js
---

# React 从入门到进阶

> 按学习阶段组织。每个阶段先讲「为什么」，再讲「怎么写」，最后补「容易踩的坑」。
>
> 心法：React 不是模板引擎，而是用 **JavaScript 描述 UI 该长什么样**。你改的是数据，界面由 React 根据数据算出来。

原稿里的 `useState` / `useRef` / `useEffect` / `forwardRef` 等内容都保留了，并纠正了几处常见误解（例如「setState 是异步的」、`useLayoutEffect` 的执行时机）。

## 目录

- [阶段一：先建立心智模型](#stage-1)
- [阶段二：JSX 与组件](#stage-2)
- [阶段三：界面怎么画出来](#stage-3)
- [阶段四：状态 useState](#stage-4)
- [阶段五：副作用 useEffect](#stage-5)
- [阶段六：useRef 与命令式句柄](#stage-6)
- [阶段七：useLayoutEffect](#stage-7)
- [阶段八：自定义 Hooks](#stage-8)
- [阶段九：数据怎么在组件树里流动](#stage-9)
- [阶段十：其余常用 Hooks](#stage-10)
- [阶段十一：渲染、协调与性能](#stage-11)
- [阶段十二：TypeScript 与 React](#stage-12)
- [阶段十三：React 19 新能力](#stage-13)
- [阶段十四：生态地图](#stage-14)
- [阶段十五：Next.js 与 Server Components](#stage-15)
- [阶段十六：工程化与避坑清单](#stage-16)

---

## 阶段一：先建立心智模型 {#stage-1}

### 1.1 React 在解决什么问题

写过原生 DOM 或 jQuery 就会遇到：数据一变，你要亲手改好几处节点，还要小心漏改、改乱。页面复杂之后，**「数据和界面不同步」** 是最大的麻烦。

React 的做法是：

1. 用组件把界面拆成一块块可组合的函数
2. 用 **state / props** 描述当前该显示什么
3. 数据变了，React 重新计算 UI，再高效地更新真实 DOM

你几乎不再直接操作 DOM（`useRef` 是少数例外）。

### 1.2 声明式 vs 命令式

命令式（告诉浏览器「怎么做」）：

```js
const el = document.getElementById("count");
el.textContent = String(Number(el.textContent) + 1);
el.classList.toggle("highlight", Number(el.textContent) > 10);
```

声明式（告诉 React「长什么样」）：

```tsx
function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button
      className={count > 10 ? "highlight" : undefined}
      onClick={() => setCount((c) => c + 1)}
    >
      {count}
    </button>
  );
}
```

同一份数据只会对应一种界面。这就是 React 的核心承诺。

### 1.3 Virtual DOM 和 Fiber，先知道干什么

第一次接触常听到「虚拟 DOM 很快」。更准确的说法是：

- **Virtual DOM**：用 JS 对象描述 UI 树，方便对比「上次」和「这次」差在哪
- **协调（Reconciliation）**：对比两棵树，算出最小 DOM 改动
- **Fiber**：React 16 之后的内部架构。把更新拆成可中断的小任务，让高优先级更新（输入、动画）不被大更新卡住

入门阶段不必手写 Fiber。记住两句话就够：

1. **state 变 → 函数组件再跑一遍 → 生成新的 UI 描述 → React 去改 DOM**
2. 组件函数会被反复执行，所以不要把「只该发生一次」的事情随手写在函数体里

### 1.4 用 Vite 跑起来

现代 React 项目几乎都用 [Vite](https://vite.dev/) 起手，开发时按需编译、热更新很快。

```bash
pnpm create vite my-app --template react-ts
cd my-app
pnpm install
pnpm dev
```

入口一般是：

```tsx
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

:::tip
React 17 之前用 `ReactDOM.render`。现在统一用 `createRoot`（React 18+），才能用上自动批处理、并发特性。
:::

### 1.5 React.StrictMode

开发环境下，`StrictMode` 会故意把某些逻辑跑两遍，帮你发现「不纯」的组件：函数组件应该只根据 props / state 计算 UI，副作用要放进 Effect。

```tsx
createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

常见现象：`useState` 初始化函数、`useEffect` 在开发模式会看起来执行了两次。这是 **只在开发环境** 的行为，生产环境不会双调用。

:::warning
不要为了「少打印两次」去关掉 StrictMode。双调用暴露的是：你把副作用写进了渲染过程，或 Effect 的清理函数不完整。
:::

---

## 阶段二：JSX 与组件 {#stage-2}

### 2.1 JSX 是什么

JSX 看起来像 HTML，其实是 `React.createElement`（或编译器生成的 `jsx()`）的语法糖：

```tsx
const el = <h1 className="title">Hello</h1>;

// 大致等价于
const el2 = React.createElement("h1", { className: "title" }, "Hello");
```

几个和 HTML 不同的点：

| HTML | JSX | 原因 |
|------|-----|------|
| `class` | `className` | `class` 是 JS 保留字 |
| `for` | `htmlFor` | `for` 是保留字 |
| `style="color: red"` | `style={{ color: "red" }}` | style 必须是对象 |
| 注释 `<!-- -->` | `{/* */}` | 花括号里写 JS |
| 多个根节点要包一层 | 可用 `<>...</>` Fragment | 少一层无意义 DOM |

花括号里可以放任意 JS 表达式（不能直接放 `if` 语句）：

```tsx
<p>{user ? user.name : "游客"}</p>
<p>{list.map((item) => item.title).join("、")}</p>
```

### 2.2 函数组件

现在的 React 以 **函数组件 + Hooks** 为主。类组件还能见到，新代码不必再写。

```tsx
function Hello({ name }: { name: string }) {
  return <p>你好，{name}</p>;
}
```

组件约定：

1. 函数名大写（`Hello` 是组件，`hello` 会被当成普通 HTML 标签）
2. **必须返回** 可渲染的内容：元素、`null`、字符串、数组、Fragment
3. 同样的 props，应当得到同样的 UI（尽量保持纯净）

### 2.3 `React.FC` 还是显式声明 props

旧笔记里常见这种写法：

```tsx
const App: React.FC = () => {
  return <div>app</div>;
};
```

`React.FC<T>` 表示「这是一个函数组件」，泛型 `T` 用来约束 props。

现在更推荐 **直接给参数写类型**，意图更清楚，也不依赖 `FC` 隐式带上的 `children`：

```tsx
type AppProps = {
  title: string;
  children?: React.ReactNode;
};

function App({ title, children }: AppProps) {
  return (
    <section>
      <h1>{title}</h1>
      {children}
    </section>
  );
}
```

两种都能用。团队统一一种即可。本笔记后面用显式 props。

### 2.4 Props 是单向数据流

父 → 子 传数据用 props。子组件 **不要改 props**，要改就通知父组件（回调）：

```tsx
function Child({ count, onAdd }: { count: number; onAdd: () => void }) {
  return <button onClick={onAdd}>点了 {count} 次</button>;
}

function Parent() {
  const [count, setCount] = useState(0);
  return <Child count={count} onAdd={() => setCount((c) => c + 1)} />;
}
```

`children` 是一种特殊 props，用来做插槽：

```tsx
function Card({ children }: { children: React.ReactNode }) {
  return <div className="card">{children}</div>;
}

<Card>
  <p>任意内容</p>
</Card>
```

### 2.5 组合优于继承

React 不靠类继承扩展 UI，而是靠 **组合**：把组件当积木嵌套在一起。需要「把一块 UI 插到指定位置」时，用 `children` 或多个 render props，而不是去继承某个基类组件。

---

## 阶段三：界面怎么画出来 {#stage-3}

### 3.1 条件渲染

```tsx
{isLogin && <UserPanel />}
{isLogin ? <UserPanel /> : <LoginButton />}
{status === "error" && <ErrorTip />}
```

`&&` 要注意：`0 && <div />` 会渲染出 `0`。数字用 `count > 0 && ...` 更安全。

不想渲染任何东西时返回 `null`：

```tsx
function Banner({ show }: { show: boolean }) {
  if (!show) return null;
  return <div>通知</div>;
}
```

### 3.2 列表和 key

```tsx
<ul>
  {todos.map((todo) => (
    <li key={todo.id}>{todo.text}</li>
  ))}
</ul>
```

`key` 帮 React 识别「哪一项是哪一项」。用稳定的 **业务 id**，不要用 index（列表会插入、删除、排序时，index 会错位，导致状态绑错）。

### 3.3 事件

React 事件名是小驼峰，传的是函数，不是字符串：

```tsx
<button onClick={handleClick}>点我</button>
<input onChange={(e) => setValue(e.target.value)} />
<form onSubmit={(e) => { e.preventDefault(); submit(); }} />
```

需要传参数时包一层，避免渲染时就调用：

```tsx
// 错：每次渲染立刻执行
<button onClick={deleteItem(id)}>删除</button>

// 对
<button onClick={() => deleteItem(id)}>删除</button>
```

### 3.4 表单：受控 vs 非受控

**受控**：输入框的值来自 state，输入时更新 state。表单的唯一数据源在 React 里，校验、禁用、联动都好做。

```tsx
function Search() {
  const [keyword, setKeyword] = useState("");
  return (
    <input
      value={keyword}
      onChange={(e) => setKeyword(e.target.value)}
    />
  );
}
```

**非受控**：值放在 DOM 里，需要时用 ref 读取。适合「提交时才关心值」的简单表单，或必须对接非 React 的原生控件。

日常以受控为主。

---

## 阶段四：状态 useState {#stage-4}

`useState` 是函数组件里保存「会随时间变化的数据」的方式。

```tsx
const [count, setCount] = useState(0);
```

返回值是 `[当前值, 更新函数]`。调用 `setCount` 之后，React 会安排一次重新渲染，组件函数再跑一遍，拿到新的 `count`。

### 4.1 状态变化会让函数组件重新执行

这是整份笔记里最重要的一句话：

> 在函数组件里用 `useState` 定义状态之后，状态改变会触发组件重新执行，从而根据最新数据更新 DOM。

:::tip
组件重新执行时，**不会**再走一遍 `useState(0)` 去把数据重置成 0。React 按 Hooks 调用顺序，把上次的 state 复用回来。
:::

所以下面这段是安全的：

```tsx
function Counter() {
  const [count, setCount] = useState(0); // 只有首次挂载用 0
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

这也是为什么 Hooks 必须写在顶层、不能放进 `if`：React 靠 **调用顺序** 对齐每一格 state。

### 4.2 用函数给状态赋初始值（惰性初始化）

初始值计算比较贵时（读 localStorage、`new Date()` 拆字段），传函数。这个函数 **只在首次渲染执行**：

```tsx
const [date, setDate] = useState(() => {
  const dt = new Date();
  return {
    year: dt.getFullYear(),
    month: dt.getMonth() + 1,
    day: dt.getDate(),
  };
});
```

对比：

```tsx
// 每次渲染都会执行 Date.now()，但只有第一次的结果会被用上，白算了
const [t] = useState(Date.now());

// 只在首次渲染执行
const [t2] = useState(() => Date.now());
```

### 4.3 「setState 是异步的」到底是什么意思

更准确的说法：**更新是调度出去的，不会立刻改掉当前这次渲染里的变量**。

```tsx
const [count, setCount] = useState(0);

const add = () => {
  setCount(count + 1);
  console.log(count); // 还是旧值，因为这次点击对应的渲染还没结束
};
```

React 18 起，事件处理函数里的多次 `setState` 会 **自动批处理**，合并成一次渲染，避免中间态闪烁。

想「等更新完成后再读 DOM」，用 `useEffect` 监听这个值，而不是在 `setCount` 下一行读。

```tsx
useEffect(() => {
  console.log("change", count);
}, [count]);
```

> `useEffect` 会在 **首次渲染完成之后** 执行一次；之后依赖变了再执行。

### 4.4 连续更新要用函数式写法

React 会对下一次 state 做浅比较。对象 / 数组要换新引用才会更新；对原始值来说，**两次算出相同的新值，第二次会被忽略**。

更常见的坑是闭包拿到的都是旧 `count`：

```tsx
const [count, setCount] = useState(0);

const addCount = () => {
  setCount(count + 1);
  setCount(count + 1);
};
// 点一次只 +1：两次都基于同一个旧 count
```

函数式更新会拿到 **队列里上一次更新的结果**：

```tsx
const addCount = () => {
  setCount((c) => c + 1);
  setCount((c) => c + 1);
};
// 点一次 +2
```

:::warning
`setCount(() => count + 1)` 写两遍仍然是 +1，因为闭包里的 `count` 没变。必须用参数：`setCount((c) => c + 1)`。
:::

对象、数组同样要返回 **新引用**，不要直接改原对象：

```tsx
// 错：改了同一个对象，React 可能认为没变化
user.age = 18;
setUser(user);

// 对
setUser({ ...user, age: 18 });
setList([...list, newItem]);
```

### 4.5 用 setState 模拟强制刷新

极少数情况（对接非 React 的库、必须推一次渲染）可以用「每次一个新对象」触发更新：

```tsx
function App() {
  const [, forceUpdate] = useState({});
  const onRefresh = () => forceUpdate({});

  return <button onClick={onRefresh}>刷新</button>;
}
```

更干净的写法是 `useReducer`：

```tsx
const [, forceUpdate] = useReducer((x: number) => x + 1, 0);
```

日常业务里如果总在强制刷新，多半是状态没放对位置。优先把数据放进 `useState`。

---

## 阶段五：副作用 useEffect {#stage-5}

渲染应该是纯的：给定 props / state，算出 UI。和「计算 UI」无关的事情叫 **副作用**：请求、订阅、改 `document.title`、打点、操作非 React 的 widget。

```txt
useEffect(fn, deps?)
```

### 5.1 执行时机

1. **首次渲染完成后一定会跑一次**
2. **没写 deps**：每次渲染结束后都跑（适合读最新 DOM，但很容易过度执行）
3. **deps 是 `[a, b]`**：这些值变了才跑。比较方式是 `Object.is`
4. **deps 是 `[]`**：只在挂载后跑一次，卸载时跑 cleanup。类似 Vue 的 `onMounted` + `onUnmounted`

```tsx
function App() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    console.log("触发渲染执行");
  }); // 每次渲染后

  return (
    <>
      <button onClick={() => setCount(count + 1)}>+1</button>
      <div>{count}</div>
    </>
  );
}
```

副作用函数是在 **浏览器绘制之后** 异步执行的，不阻塞首屏上色。

:::tip 注意事项
1. 不要在 Effect 里无条件修改自己的依赖，会形成「设值 → 渲染 → Effect → 设值」死循环
2. 不同的副作用拆成多个 `useEffect`，不要揉成一个大函数
3. 先问自己：这件事是不是真的需要 Effect？同步派生的值用计算即可，不必 `useEffect + setState`
:::

官方文档有一篇很值得读：[You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)。

### 5.2 清理副作用

`useEffect` 可以返回一个函数。React 会在 **下次 Effect 执行前** 以及 **组件卸载时** 调用它。定时器、事件监听、WebSocket、进行中的请求，都应该在这里拆掉。

取消请求：

```tsx
function Child() {
  const [color, setColor] = useState("");

  useEffect(() => {
    const controller = new AbortController();

    fetch("https://api.liulongbin.top/v1/color", { signal: controller.signal })
      .then((res) => res.json())
      .then((res) => setColor(res.data.color))
      .catch((err) => {
        if (err.name === "AbortError") return;
        console.log("err:", err.message);
      });

    return () => controller.abort();
  }, []);

  return <>child {color}</>;
}
```

父组件用条件渲染卸载子组件时，cleanup 会跑，进行中的 fetch 被 abort，避免「组件都没了还 setState」的警告。

清理事件监听：

```tsx
useEffect(() => {
  const onMove = (e: MouseEvent) => {
    setPosition({ x: e.clientX, y: e.clientY });
  };
  window.addEventListener("mousemove", onMove);
  return () => window.removeEventListener("mousemove", onMove);
}, []);
```

监听函数要写在 Effect 里面（或用下面的 `useEffectEvent`），这样 cleanup 移除的是 **同一份** 函数引用。

### 5.3 依赖数组和「过期闭包」

Effect 捕获的是某一次渲染里的 props / state。依赖漏了，就会用到过期值：

```tsx
useEffect(() => {
  const id = setInterval(() => {
    console.log(count); // deps 是 [] 的话，永远是 0
  }, 1000);
  return () => clearInterval(id);
}, []); // 漏了 count
```

把 `count` 放进依赖，interval 会每次重置，往往也不是你要的。这时需要把「订阅一次」和「用最新值」拆开，见 [13.4 useEffectEvent](#useeffectevent)。

### 5.4 开发模式双调用

StrictMode 下，React 会 `mount → cleanup → 再 mount`。如果你的 Effect 没有 cleanup，就会看到两次请求。正确做法是补上 abort / unsubscribe，而不是删掉 StrictMode。

---

## 阶段六：useRef 与命令式句柄 {#stage-6}

`useRef` 返回 `{ current: 初始值 }`。这个对象在组件 **整个生命周期内保持同一份引用**。

它主要做两件事：

1. 拿到 DOM 或子组件暴露出来的句柄
2. 保存跨渲染共享、但 **改了也不该触发渲染** 的数据（定时器 id、上一次的值、是否已挂载）

### 6.1 获取 DOM

```tsx
function App() {
  const inputRef = useRef<HTMLInputElement>(null);

  const getFocus = () => {
    inputRef.current?.focus();
  };

  return (
    <>
      <input type="text" ref={inputRef} />
      <button onClick={getFocus}>聚焦</button>
    </>
  );
}
```

### 6.2 跨渲染存一份数据

例如记下「上一次的 count」：

```tsx
function App() {
  const [count, setCount] = useState(0);
  const prevCountRef = useRef<number | undefined>(undefined);

  const add = () => {
    prevCountRef.current = count;
    setCount(count + 1);
  };

  return (
    <>
      <div>
        旧值：{prevCountRef.current} 新值：{count}
      </div>
      <button onClick={add}>+1</button>
    </>
  );
}
```

组件 rerender 时 **不会重新初始化** ref。下面这个时间戳在 count 变化时保持不变：

```tsx
const time = useRef<number>(Date.now());
```

（React 19 起 `useRef` 的初始参数是必填的，不再允许 `useRef()` 空调用。）

### 6.3 改 `.current` 不会触发渲染

值变了，但视图还是旧的——因为 React 根本不知道你改了 ref：

```tsx
function App() {
  const [count] = useState(0);
  const time = useRef<number>(Date.now());

  const change = () => {
    time.current = Date.now(); // 视图不会变
  };

  return (
    <>
      <div>
        {time.current} {count}
      </div>
      <button onClick={change}>change</button>
    </>
  );
}
```

这是特性：计时器 id、socket 实例就该放这里。要反映到界面上，用 `useState`。

### 6.4 不要把 `ref.current` 当其它 Hooks 的依赖

`ref` 对象本身引用不变，改 `.current` **不会** 让 `useEffect` 重跑：

```tsx
useEffect(() => {
  console.log("time 改变了");
}, [time.current]); // 改 time.current 不会打印
```

需要「值变了做点事」就用 state。ref 只适合「我自己读、自己写，不劳 React 操心」的数据。

### 6.5 父组件调用子组件方法：ref + useImperativeHandle

函数组件没有实例，不能像类组件那样 `childRef.current.xxx()`。需要主动 **暴露一份句柄**。

React 19 起，函数组件可以直接接收 `ref` 这个 props，不必再包 `forwardRef`（旧写法仍然能用，后续版本会废弃）。

```tsx
import { useImperativeHandle, useRef, useState } from "react";

type ChildHandle = {
  data: number;
  change: () => void;
};

function Child({ ref }: { ref?: React.Ref<ChildHandle> }) {
  const [data, setData] = useState(1);

  const change = () => setData((d) => d + 1);

  useImperativeHandle(ref, () => ({ data, change }), [data, change]);

  return <div>{data}</div>;
}

function App() {
  const childRef = useRef<ChildHandle>(null);

  return (
    <>
      <button onClick={() => childRef.current?.change()}>getChild</button>
      <Child ref={childRef} />
    </>
  );
}
```

`useImperativeHandle(ref, createHandle, deps)`：

- 第二个函数的返回值就是父组件从 `ref.current` 上看到的对象
- 第三个参数是依赖：`[]` 时只在挂载时创建一次句柄，父组件可能一直读到初始 `data`

:::warning
能用 props / 回调解决的，就不要用命令式 ref。句柄会把父子耦合在一起，不好测、不好想数据流。优先「数据向下、事件向上」。
:::

React 18 及更早需要 `forwardRef`：

```tsx
const Child = React.forwardRef<ChildHandle, { /* props */ }>((props, ref) => {
  useImperativeHandle(ref, () => ({ data, change }), [data, change]);
  return <div>{data}</div>;
});
```

React 19 还给 **ref 回调** 加上了 cleanup：回调可以返回一个拆卸函数，在 ref 脱离时执行。

---

## 阶段七：useLayoutEffect {#stage-7}

用法和 `useEffect` 几乎一样，**执行时机不同**。

| Hook | 时机 | 是否挡住绘制 |
|------|------|----------------|
| `useEffect` | 浏览器把这一帧画到屏幕 **之后** | 否，异步，不挡绘制 |
| `useLayoutEffect` | DOM 已更新，但浏览器绘制 **之前** | 是，**同步**执行 |

旧笔记里「`useLayoutEffect` 相当于 Vue 的 `created`」不准确：`created` 时 DOM 还不存在。`useLayoutEffect` 更接近「DOM 已经按这次渲染改好了，但用户还没看见」——适合量尺寸、同步滚动位置，避免闪一下。

```tsx
useLayoutEffect(() => {
  const { height } = boxRef.current!.getBoundingClientRect();
  if (height > 200) setCollapsed(true);
}, []);
```

:::tip
默认用 `useEffect`。只有出现「先画出错误布局，再跳到正确位置」的闪烁时，才换成 `useLayoutEffect`。它会拉长这一帧，用多了会掉帧。
:::

SSR 时 `useLayoutEffect` 会报警（服务器没有 DOM）。这种逻辑放进客户端组件，或用 `useEffect`。

---

## 阶段八：自定义 Hooks {#stage-8}

把「状态 + 副作用」打包成 `useXxx` 函数，就是自定义 Hook。规则和内置 Hook 一样：只在顶层调用、名字以 `use` 开头。

把「节流后的鼠标位置」抽出来（原稿逻辑保留，补上 `useRef` 存 timer，卸载时清掉未完成的 timeout）：

```tsx
import { useEffect, useRef, useState } from "react";

export function useMousePosition(delay = 500) {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (timerRef.current) return;
      timerRef.current = setTimeout(() => {
        setPosition({ x: e.clientX, y: e.clientY });
        timerRef.current = null;
      }, delay);
    };

    window.addEventListener("mousemove", onMove);
    return () => {
      window.removeEventListener("mousemove", onMove);
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [delay]);

  return position;
}
```

使用：

```tsx
function Child() {
  const position = useMousePosition();
  return (
    <>
      鼠标位置：{position.x}, {position.y}
    </>
  );
}
```

好的自定义 Hook 只暴露业务语义（`useMousePosition`），把订阅细节藏起来。常见还有 `useLocalStorage`、`useMediaQuery`、`useDebouncedValue`。能用现成库（[ahooks](https://ahooks.js.org/)、[usehooks-ts](https://usehooks-ts.com/)）就不必每个项目重写一遍。

---

## 阶段九：数据怎么在组件树里流动 {#stage-9}

### 9.1 状态提升

两个子组件要共用一份数据：把 state 放到最近的共同父组件，再通过 props 往下传。这是 React 最朴素、也最清晰的数据流。

### 9.2 Context：避免一层层传 props

跨很多层、改得不频繁的数据（主题、当前用户、i18n）适合 Context：

```tsx
const ThemeContext = createContext<"light" | "dark">("light");

function App() {
  const [theme, setTheme] = useState<"light" | "dark">("light");
  return (
    <ThemeContext value={theme}>
      <Page />
      <button onClick={() => setTheme((t) => (t === "light" ? "dark" : "light"))}>
        切换
      </button>
    </ThemeContext>
  );
}

function Title() {
  const theme = useContext(ThemeContext);
  return <h1 data-theme={theme}>标题</h1>;
}
```

React 19 起可以直接写 `<ThemeContext value={theme}>`，不必再写 `<ThemeContext.Provider>`。

:::warning
Context 的 `value` 一变，所有 `useContext` 了它的组件都会重渲染。不要把高频变化的大对象塞进同一个 Context。高频状态更适合状态库，或把 Context 拆细。
:::

### 9.3 什么时候还不够

| 场景 | 更合适的工具 |
|------|----------------|
| 父子、少量层级 | props |
| 主题 / 登录用户 | Context |
| 跨页面的客户端全局状态 | Zustand / Jotai 等 |
| 服务端数据（列表、详情、缓存、重试） | TanStack Query |
| 超大表单 | React Hook Form |

不要一上来就把所有东西丢进 Redux。先 props，再 Context，不够再用库。

---

## 阶段十：其余常用 Hooks {#stage-10}

### 10.1 useReducer

状态转移规则比较多（状态机、多字段互相影响）时，比一堆 `useState` 更清晰：

```tsx
type State = { count: number };
type Action = { type: "inc" } | { type: "dec" } | { type: "set"; value: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "inc":
      return { count: state.count + 1 };
    case "dec":
      return { count: state.count - 1 };
    case "set":
      return { count: action.value };
    default:
      return state;
  }
}

const [state, dispatch] = useReducer(reducer, { count: 0 });
dispatch({ type: "inc" });
```

Redux 的思路和它一脉相承，只是把 reducer 放到了全局。

### 10.2 useMemo 与 useCallback

```tsx
const filtered = useMemo(
  () => list.filter((x) => x.includes(keyword)),
  [list, keyword],
);

const onSave = useCallback(() => save(form), [form]);
```

- `useMemo`：缓存 **计算结果**
- `useCallback`：缓存 **函数引用**（本质是 `useMemo(() => fn, deps)`）

它们解决的是「每次渲染都是新引用，导致子组件 / Effect 误以为变了」。没有测量就不要先包一层。React 19 搭配 **React Compiler** 后，很多场景编译器会自动插入等价优化，手写 memo 会越来越少。

### 10.3 useId

生成 SSR 和客户端一致的唯一 id，给 `htmlFor` / `aria-*` 用，不要用 `Math.random()`。

```tsx
const id = useId();
return (
  <>
    <label htmlFor={id}>邮箱</label>
    <input id={id} />
  </>
);
```

### 10.4 useTransition 与 useDeferredValue

把更新分成「紧急」和「可延迟」：输入框保持跟手，下面的大列表可以稍后渲染。

```tsx
const [keyword, setKeyword] = useState("");
const [isPending, startTransition] = useTransition();

const onChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const value = e.target.value;
  setKeyword(value); // 紧急：输入框
  startTransition(() => {
    setQuery(value); // 可延迟：过滤结果
  });
};
```

`useDeferredValue(value)` 则是：我先用旧值渲染，新值在空闲时再跟上。适合「源值在父组件，我这边自己降频」。

### 10.5 useSyncExternalStore

订阅外部数据源（Redux store、浏览器 `matchMedia`、`window.location`），并与并发渲染兼容。自己写全局 store 时优先用它，不要 `useEffect` + `setState` 去同步，避免 tearing。

### 10.6 use（React 19）

`use` 可以在组件或 Hook 里读取 Promise 或 Context。读取 Promise 时，外层要有 `<Suspense>`：

```tsx
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  return comments.map((c) => <p key={c.id}>{c.text}</p>);
}

<Suspense fallback={<p>加载中…</p>}>
  <Comments commentsPromise={fetchComments()} />
</Suspense>
```

它不像其它 Hook，可以写在 `if` 后面（但仍不能写在循环 / 普通回调里）。`try/catch` 包 `use` 是不允许的，错误交给 Error Boundary。

---

## 阶段十一：渲染、协调与性能 {#stage-11}

### 11.1 一次更新经历什么

1. **触发**：`setState`、父组件重渲染、Context 变化、钩子订阅的外部 store 变了
2. **渲染**：组件函数执行，算出新的 React 元素树
3. **协调**：和上次的树对比（同层、同 `key` 才认为是同一个组件）
4. **提交**：改 DOM，跑 `useLayoutEffect`，浏览器绘制，再跑 `useEffect`

父组件重渲染，默认子组件也会重渲染，即使传给它的 props 「看起来一样」（函数、对象每次都是新引用）。

### 11.2 减少无效渲染

- 状态尽量放在真正需要它的那一层，避免「顶层一个大 state 整页跟着抖」
- 列表用稳定 `key`
- 用 `React.memo` 包纯展示组件，配合稳定的 props 引用
- 大列表用虚拟列表（`@tanstack/react-virtual`）
- 图片、路由级代码用 `lazy` + `Suspense` 拆包

```tsx
const HeavyChart = lazy(() => import("./HeavyChart"));

<Suspense fallback={<div>加载图表…</div>}>
  <HeavyChart />
</Suspense>
```

### 11.3 React Compiler

[React Compiler](https://react.dev/learn/react-compiler) 1.0 已在 2025 年 10 月稳定。它在编译期自动做等价于 `memo` / `useMemo` / `useCallback` 的优化。新项目可以按官方指南接入；没开编译器时，仍按上面的规则手写。

### 11.4 错误边界

渲染阶段抛出的异常，不能像事件处理函数那样用 `try/catch` 接住。用 Error Boundary（类组件，或 `react-error-boundary` 这种封装）兜住子树，避免整页白屏。

---

## 阶段十二：TypeScript 与 React {#stage-12}

### 12.1 组件 props

```tsx
type ButtonProps = {
  variant?: "primary" | "ghost";
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
};

function Button({ variant = "primary", children, ...rest }: ButtonProps) {
  return (
    <button data-variant={variant} {...rest}>
      {children}
    </button>
  );
}
```

延伸原生元素属性：

```tsx
type InputProps = React.ComponentPropsWithoutRef<"input"> & {
  label: string;
};

type InputPropsWithRef = React.ComponentPropsWithRef<"input">;
```

React 19 给组件加 `ref` 时，把 `ref` 写进 props 即可：

```tsx
type FieldProps = {
  label: string;
  ref?: React.Ref<HTMLInputElement>;
};
```

### 12.2 事件类型

```tsx
function onChange(e: React.ChangeEvent<HTMLInputElement>) {}
function onSubmit(e: React.FormEvent<HTMLFormElement>) {}
function onClick(e: React.MouseEvent<HTMLButtonElement>) {}
```

### 12.3 带泛型的组件

```tsx
type SelectProps<T> = {
  options: T[];
  value: T;
  onChange: (value: T) => void;
  getLabel: (item: T) => string;
};

function Select<T extends string | number>({
  options,
  value,
  onChange,
  getLabel,
}: SelectProps<T>) {
  return (
    <select value={value} onChange={(e) => onChange(e.target.value as T)}>
      {options.map((opt) => (
        <option key={String(opt)} value={opt}>
          {getLabel(opt)}
        </option>
      ))}
    </select>
  );
}
```

---

## 阶段十三：React 19 新能力 {#stage-13}

下面以 React 19 / 19.2 为准（到 2026 年已是主流版本）。新项目按 19 来学即可。

### 13.1 Actions：把 pending / 错误从手搓逻辑里拿走

把异步函数丢进 `startTransition`，或作为 `<form action={fn}>`。React 会跟踪进行中的请求。

```tsx
async function saveUser(formData: FormData) {
  "use server"; // 在支持 Server Actions 的框架里
  await db.user.update({ name: String(formData.get("name")) });
}

<form action={saveUser}>
  <input name="name" />
  <button type="submit">保存</button>
</form>
```

纯客户端也可以把 async 函数交给 `useTransition` / `useActionState`。

### 13.2 useActionState / useFormStatus / useOptimistic

```tsx
const [error, submitAction, isPending] = useActionState(
  async (_prev: string | null, formData: FormData) => {
    const result = await updateName(String(formData.get("name")));
    if (result.error) return result.error;
    return null;
  },
  null,
);

<form action={submitAction}>
  <input name="name" />
  <SubmitButton />
  {isPending && <span>提交中…</span>}
  {error && <p>{error}</p>}
</form>
```

`useFormStatus` 在 **表单内部的子组件** 里读提交状态，不用一层层传 `isPending`：

```tsx
function SubmitButton() {
  const { pending } = useFormStatus();
  return <button disabled={pending}>{pending ? "提交中" : "提交"}</button>;
}
```

`useOptimistic`：先按「成功后应该长什么样」更新界面，请求失败再自动回滚。

```tsx
const [optimisticList, addOptimistic] = useOptimistic(
  todos,
  (state, newItem: Todo) => [...state, newItem],
);
```

### 13.3 Activity：隐藏但保留状态（19.2）

以前用 `{show && <Page />}` 卸载子树，再打开时状态全丢。`<Activity>` 可以藏起一块 UI、拆掉它的 Effect，但 **保留内部 state**，适合预渲染下一个 Tab、或把刚离开的页面停在后台。

```tsx
import { Activity } from "react";

<Activity mode={tab === "home" ? "visible" : "hidden"}>
  <Home />
</Activity>
<Activity mode={tab === "profile" ? "visible" : "hidden"}>
  <Profile />
</Activity>
```

`hidden`：不显示、卸载 Effect、更新降到低优先级。`visible`：正常显示和更新。

### 13.4 useEffectEvent：把「事件」从 Effect 里拆出去 {#useeffectevent}

Effect 要订阅一次，但回调里要用 **最新的** props / state。以前用 ref 手动同步，现在用 `useEffectEvent`：

```tsx
const onMessage = useEffectEvent((msg: string) => {
  showNotification(msg, theme); // 永远是最新 theme
});

useEffect(() => {
  const conn = connect(roomId);
  conn.on("message", onMessage);
  return () => conn.disconnect();
}, [roomId]); // 不要把 onMessage 放进依赖
```

规则：`useEffectEvent` 只在 Effect 里调用；它不是响应式依赖，换 theme **不会** 重连房间。

### 13.5 文档元数据

组件里直接渲染 `<title>`、`<meta>`、`<link>`，React 19 会把它们提升到 `document.head`，很多场景不必再上 `react-helmet`。

```tsx
function BlogPost({ post }: { post: Post }) {
  return (
    <>
      <title>{post.title}</title>
      <meta name="description" content={post.summary} />
      <article>{post.body}</article>
    </>
  );
}
```

---

## 阶段十四：生态地图 {#stage-14}

React 本身只负责 UI。真正做项目时，周围一圈工具要会选型。

```txt
构建     Vite（SPA） / Next.js、Remix（全栈框架）
语言     TypeScript
路由     React Router（SPA） / 框架自带文件系统路由
客户端状态  Zustand、Jotai；复杂时 Redux Toolkit
服务端状态  TanStack Query（缓存、重试、失效）
表单     React Hook Form + Zod
样式     CSS Modules、Tailwind CSS、Panda、shadcn/ui
测试     Vitest + React Testing Library
质量     ESLint（eslint-plugin-react-hooks）、Prettier
```

### 14.1 路由：React Router

SPA 用 [React Router](https://reactrouter.com/)（v6/v7 都是 data API 这一套）：

```tsx
import { createBrowserRouter, RouterProvider, Link, useLoaderData } from "react-router";

const router = createBrowserRouter([
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <Home /> },
      {
        path: "posts/:id",
        element: <Post />,
        loader: async ({ params }) => {
          const res = await fetch(`/api/posts/${params.id}`);
          return res.json();
        },
      },
    ],
  },
]);

createRoot(document.getElementById("root")!).render(
  <RouterProvider router={router} />,
);
```

```tsx
function Layout() {
  return (
    <>
      <nav>
        <Link to="/">首页</Link>
      </nav>
      <Outlet />
    </>
  );
}
```

要点：

- 用 `<Link>` 不要用 `<a href>`，以免整页刷新
- `loader` / `action` 把取数、提交和路由绑在一起，页面组件可以更薄
- 需要 SSR、文件路由、SEO 时，优先考虑 Next.js，而不是在 SPA 上硬补

### 14.2 客户端状态：Zustand 足够覆盖大多数项目

[Zustand](https://zustand-demo.pmnd.rs/) API 小、没有样板代码：

```tsx
import { create } from "zustand";

type UserState = {
  token: string | null;
  setToken: (token: string | null) => void;
  logout: () => void;
};

export const useUserStore = create<UserState>((set) => ({
  token: null,
  setToken: (token) => set({ token }),
  logout: () => set({ token: null }),
}));

// 组件里按字段取，避免无关更新
const token = useUserStore((s) => s.token);
```

Jotai 更偏「原子」、自底向上；Redux Toolkit 适合超大型团队、要强约束时间旅行调试、中间件生态。个人和中小项目 Zustand 通常更舒服。

### 14.3 服务端状态：TanStack Query

列表、详情、轮询、失效刷新，**不是** 再手写一遍 `useEffect + fetch + loading + error`。

```tsx
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

function Post({ id }: { id: string }) {
  const { data, isPending, error } = useQuery({
    queryKey: ["post", id],
    queryFn: () => fetch(`/api/posts/${id}`).then((r) => r.json()),
  });

  if (isPending) return <p>加载中</p>;
  if (error) return <p>失败</p>;
  return <article>{data.title}</article>;
}

function useAddPost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: PostBody) =>
      fetch("/api/posts", { method: "POST", body: JSON.stringify(body) }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["posts"] }),
  });
}
```

记住分工：

- **TanStack Query**：服务器上那份数据的缓存
- **Zustand**：当前用户、侧边栏是否打开、向导走到第几步

两边不要存同一份列表。

### 14.4 样式

| 方案 | 适合 |
|------|------|
| CSS Modules | 和组件绑定、类名自动哈希，零新概念 |
| Tailwind CSS | 实用优先、设计系统好统一，现在非常主流 |
| CSS-in-JS（emotion 等） | 运行时样式；RSC 场景要选支持零运行时的方案 |
| shadcn/ui | 把组件源码拷进项目，搭配 Tailwind，改得动 |

组件库常见选择：shadcn/ui、Ant Design、MUI、Arco。后台系统 Antd 仍然好用；要高度定制品牌站，shadcn 更合适。

### 14.5 表单：React Hook Form

非受控为主、订阅粒度细，大表单不会每个按键都重渲染整个 Form。用 Zod 做 schema，提交前和服务器共用同一套校验。

```tsx
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

function Login() {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(schema),
  });

  return (
    <form onSubmit={handleSubmit((values) => console.log(values))}>
      <input {...register("email")} />
      {errors.email && <span>{errors.email.message}</span>}
      <button type="submit">登录</button>
    </form>
  );
}
```

---

## 阶段十五：Next.js 与 Server Components {#stage-15}

React 可以只做客户端 SPA。但 SEO、首屏、按路由拆数据，最后都会碰到「需要一个框架」。2026 年最常见的选择是 [Next.js](https://nextjs.org/)（App Router）。

### 15.1 为什么还要框架

Vite SPA：浏览器下载 JS → 执行 React → 再去请求数据 → 才能看见完整内容。

有服务端的框架可以：

- 在服务器上先把 HTML 渲染出来（更快的首屏、更好的 SEO）
- 用 **Server Components** 把「只在服务端跑」的代码从浏览器包里拿掉（直接读数据库、用密钥）
- 用文件路由省掉手写路由表

### 15.2 Server Components vs Client Components

App Router 里，**组件默认是服务端组件**：不能用 `useState` / `useEffect`，也不能绑浏览器事件。需要交互时，文件顶部加：

```tsx
"use client";

import { useState } from "react";

export function LikeButton() {
  const [n, setN] = useState(0);
  return <button onClick={() => setN((x) => x + 1)}>{n}</button>;
}
```

推荐结构：页面、布局、取数用 Server Component；按钮、输入框、带 Hook 的小岛用 Client Component。不要把整页标成 `"use client"`。

服务端组件可以直接 `async`：

```tsx
export default async function PostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = await db.post.findUnique({ where: { id } });
  return <article>{post?.title}</article>;
}
```

### 15.3 数据放到哪

| 需求 | 做法 |
|------|------|
| 首屏文章内容 | Server Component 里 await |
| 点赞、评论输入 | Client Component + Server Action 或 API |
| 登录后的个性化列表 | 服务端读 cookie / session 再渲染 |
| 高度交互的仪表盘 | 客户端 + TanStack Query |

能在服务端拿的数据，就不要进浏览器再 `useEffect` 拉一遍。那是 SPA 时代的习惯，在 App Router 里会拖慢首屏、还容易闪 loading。

### 15.4 其它框架

- **Vite + React Router**：管理后台、已登录的纯应用，足够
- **Next.js**：要 SEO、营销站 + 应用、全栈 API 同一仓库
- **Remix / React Router 7 框架模式**：更强调 Web 标准（Form、loader）
- 部署在 Vercel 时，默认是 Fluid Compute 上的 Node 运行时；流式 HTML、SSE 都不需要再指定 Edge Runtime

:::warning 安全
使用 React Server Components / Next.js 时，保持 `react`、`react-dom`、`next` 为当前补丁版本。RSC 协议出过严重漏洞（如 CVE-2025-55182），升级比「自己关特性」更重要。
:::

---

## 阶段十六：工程化与避坑清单 {#stage-16}

### 16.1 质量工具

```bash
pnpm add -D eslint @eslint/js eslint-plugin-react-hooks typescript
```

`eslint-plugin-react-hooks` 会检查：

- Hooks 是否在顶层调用
- Effect 依赖是否写全
- `useEffectEvent` 有没有被错误地放进依赖数组

### 16.2 测试思路

[React Testing Library](https://testing-library.com/react) 的原则是 **按用户看到的来测**，少测内部 state。

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

test("点击后数字 +1", async () => {
  const user = userEvent.setup();
  render(<Counter />);
  await user.click(screen.getByRole("button", { name: /0/ }));
  expect(screen.getByRole("button", { name: /1/ })).toBeInTheDocument();
});
```

### 16.3 Hooks 规则（背下来）

1. 只在函数组件或自定义 Hook **顶层** 调用 Hook
2. 不要在循环、条件、嵌套函数里调用（`use()` 读取 Promise/Context 是例外，但仍不能在循环里）
3. 自定义 Hook 以 `use` 开头，这样 linter 才认
4. 依赖数组用 `Object.is` 比较，对象 / 函数每次新建都算「变了」

### 16.4 一份日常避坑清单

- 在组件函数体里直接 `fetch` / `subscribe`（应放到 Effect、事件、或服务端组件）
- `useEffect(() => { setState(derive(props)) }, [props])` 能改成渲染期间直接计算就不要 Effect
- 列表 `key={index}`
- `setState` 里改原对象 / 原数组
- 把 `ref.current` 放进依赖
- 为了消 ESLint 警告把无关东西塞进 deps，或用 `eslint-disable` 糊弄过去
- 超大 Context 导致半个应用重渲染
- 客户端包进了本该只在服务端的密钥、SDK
- 开发环境 Effect 跑两次就删 StrictMode

### 16.5 建议的学习顺序（对照本文）

1. JSX、组件、props、列表 key（阶段二、三）
2. `useState`、受控表单（阶段四）
3. `useEffect` 与 cleanup（阶段五）
4. `useRef`、自定义 Hook（阶段六、八）
5. 路由 + 一个状态库 + TanStack Query（阶段十四）
6. TypeScript 把常用组件补全类型（阶段十二）
7. 需要 SEO / 全栈时再上 Next.js（阶段十五）
8. 并发特性、Compiler、Activity 等按项目需要补（阶段十一、十三）

读官方文档比刷 API 列表有效：[react.dev/learn](https://react.dev/learn)。把「Thinking in React」那一章过完，后面的 Hook 都只是这个模型的零件。
