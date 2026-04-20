---
title: Prisma规范操作文档
description: Prisma规范操作文档
category: 笔记
---


# 🧱 Nest + Prisma 规范操作文档（生产级）

---

# 1️⃣ 项目基础结构规范

```bash
commossoin-node/
├─ prisma/
│  ├─ schema.prisma
│  └─ migrations/
├─ src/
├─ .env
├─ package.json
```

---

# 2️⃣ 环境变量规范

`.env`（项目根目录）：

```env
DATABASE_URL="postgresql://user:password@127.0.0.1:5432/db"
NODE_ENV=development
```

### 规范要求

* 所有环境必须配置 `DATABASE_URL`
* 不要写死在代码里
* 生产环境用服务器 `.env` 或 PM2 注入

---

# 3️⃣ schema.prisma 编写规范

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

---

## ✅ Model 规范

```prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### 规范建议

* 每个表必须有主键 `@id`
* 时间字段统一：

  * `createdAt`
  * `updatedAt`
* 唯一字段必须加 `@unique`
* 关系必须显式定义（不要隐式）

---

# 4️⃣ 开发流程（核心）

👉 所有表结构变更必须走 migration

---

## 标准流程

### ① 修改 schema

```prisma
model User {
  id    Int    @id @default(autoincrement())
  email String @unique
  age   Int?   // 新增字段
}
```

---

### ② 生成 migration

```bash
pnpm prisma migrate dev --name add_user_age
```

---

### ③ 自动完成

这个命令会：

* 生成 SQL
* 更新数据库
* 生成 Prisma Client

---

### ❗规范要求

* 每次 schema 修改必须执行 `migrate dev`
* migration name 必须有意义（禁止 init1 / test）

---

# 5️⃣ Prisma Client 使用规范

---

## 初始化（Nest 推荐方式）

```ts
import { PrismaClient } from '@prisma/client'

export class PrismaService extends PrismaClient {}
```

---

## CRUD 示例

### 新增

```ts
await prisma.user.create({
  data: {
    email: 'a@test.com',
    name: 'Tom'
  }
})
```

---

### 查询

```ts
await prisma.user.findMany({
  where: {
    email: {
      contains: 'test'
    }
  },
  orderBy: {
    id: 'desc'
  }
})
```

---

### 更新

```ts
await prisma.user.update({
  where: { id: 1 },
  data: { name: 'NewName' }
})
```

---

### 删除

```ts
await prisma.user.delete({
  where: { id: 1 }
})
```

---

# 6️⃣ 关联关系规范

---

## 一对多

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  title    String
  authorId Int
  author   User @relation(fields: [authorId], references: [id])
}
```

---

## 查询关联

```ts
await prisma.user.findMany({
  include: {
    posts: true
  }
})
```

---

# 7️⃣ 本地数据库管理

---

## 重置数据库

```bash
pnpm prisma migrate reset
```

---

## 仅同步 schema（不推荐长期用）

```bash
pnpm prisma db push
```

---

### 规范要求

| 命令             | 是否推荐   |
| -------------- | ------ |
| migrate dev    | ✅      |
| migrate deploy | ✅      |
| db push        | ⚠️ 仅开发 |
| db pull        | ✅（接老库） |

---

# 8️⃣ 生产部署规范（重点）

---

## 🚀 服务器部署流程

```bash
git pull

pnpm install --frozen-lockfile

pnpm prisma generate
pnpm prisma migrate deploy

pnpm build

pm2 reload my-app
```

---

## ❗规范要求

* 生产禁止使用：

  * `migrate dev`
  * `db push`
* 只能使用：

  * `migrate deploy`

---

# 9️⃣ migration 管理规范

---

## 目录结构

```bash
prisma/migrations/
  ├─ 20250401_init/
  │   └─ migration.sql
  ├─ 20250402_add_user_age/
```

---

## 规范要求

* 必须提交到 Git
* 不允许删除历史 migration
* 不允许修改已执行 migration

---

# 🔟 Git 提交规范

---

每次数据库变更必须提交：

```bash
prisma/schema.prisma
prisma/migrations/
```

---

## 提交示例

```bash
feat: add user age field
```

---

# 1️⃣1️⃣ 数据初始化（Seed）

---

## seed.ts

```ts
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  await prisma.user.create({
    data: {
      email: 'admin@test.com',
      name: 'Admin'
    }
  })
}

main()
```

---

## 执行

```bash
pnpm prisma db seed
```

---

# 1️⃣2️⃣ 多环境规范

---

## .env

```env
# 本地
DATABASE_URL=xxx_dev

# 生产
DATABASE_URL=xxx_prod
```

---

## PM2 配置

```js
env_production: {
  DATABASE_URL: 'xxx_prod'
}
```

---

# 1️⃣3️⃣ 标准开发 → 上线流程

---

## 本地开发

```bash
pnpm prisma migrate dev --name xxx
git commit
git push
```

---

## 服务器

```bash
git pull
pnpm prisma migrate deploy
pm2 reload
```

---

# 1️⃣4️⃣ 必须遵守的 10 条规则（重点）

---

1. ❗禁止长期使用 `db push`
2. ❗所有结构变更必须走 migration
3. ❗migration 必须提交 Git
4. ❗生产只用 `migrate deploy`
5. ❗禁止修改历史 migration
6. ❗必须有 `DATABASE_URL`
7. ❗schema 改完必须 `generate`
8. ❗每个表必须有主键
9. ❗必须有时间字段（建议）
10. ❗上线前必须跑 migrate

---

# ✅ 一句话总结

👉 **开发用 migrate dev，生产用 migrate deploy，结构变更必须有 migration 记录**

---

