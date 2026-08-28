---
title: Go学习笔记  
description: Go学习笔记
category: Go
tag:
  - Go
---

# Go 语言学习笔记


>本笔记按学习阶段组织，每个知识点都会和你熟悉的 JavaScript 做对比，帮助你快速建立映射。

> 心法：Go 是**静态类型 + 编译型**语言，JS 是**动态类型 + 解释型**语言。很多概念相通，但 Go 更强调「显式」「安全」「并发」。


## 阶段一：环境与第一个程序

### 1.1 安装与工具链

| 概念 | JavaScript | Go |
|------|-----------|----|
| 运行环境 | Node.js / 浏览器 | Go 运行时（编译后生成二进制） |
| 包管理 | npm / yarn / pnpm | `go mod`（内置） |
| 代码格式化 | Prettier（第三方） | `gofmt`（内置，无争议） |
| 静态检查 | ESLint | `go vet`（内置） |

```bash
# 初始化一个 Go 模块（类似 npm init）
go mod init myproject

# 运行
go run main.go

# 编译成可执行文件
go build main.go
```

### 1.2 第一个程序

```go
package main  // 每个 Go 文件必须属于某个包；main 包是程序入口

import "fmt"  // 导入标准库，类似 import fs from 'fs'

func main() {  // main 函数是程序入口，类似 JS 的入口
    fmt.Println("Hello, Go!")
}
```

**对比 JS：**
- JS：`console.log("Hello")`
- Go：`fmt.Println("Hello")`
- Go 的花括号 `{` 必须和函数声明在同一行，不能换行（编译器强制）。
- Go 不需要分号结尾（编译器自动插入分号）。

### 1.3 代码结构约定

Go 强制了一种统一的代码风格，这是它和 JS 最大的文化差异：
- 用 `gofmt` 格式化，所有人代码风格一致，不再争论「用 tab 还是空格」。
- 用 `goimports` 自动管理 import 语句（类似 IDE 的自动 import）。

---

## 阶段二：变量、常量与基本类型

### 2.1 变量声明

JavaScript：
```js
let name = "Alice";     // 可变
const age = 18;         // 不可变
```

Go：
```go
var name string = "Alice"  // 显式声明类型
var age = 18               // 类型推断（推导为 int）

// 短变量声明（最常用，只能在函数内部用）
name := "Alice"            // 等价于 var name = "Alice"
```

**核心差异：**
- Go 用 `:=` 短声明，类似 JS 的 `let` 但类型固定后不能变。
- JS 的 `let` 可以 `let x = 1; x = "hello"`，Go 不行，类型一旦确定就锁死。
- Go 没有 `let / const / var` 三选一的纠结，函数外只能用 `var`，函数内推荐用 `:=`。

### 2.2 常量

```js
const PI = 3.14;
```

```go
const PI = 3.14  // Go 的 const 在编译期确定，不能是函数返回值
```

Go 的 `const` 比 JS 严格：值必须在编译时就能确定，不能是运行时计算的结果（如 `const x = math.Sin(1)` 不行）。

### 2.3 基本类型对照表

| 含义 | JavaScript | Go | 说明 |
|------|-----------|----|----|
| 字符串 | `string` | `string` | Go 的 string 是不可变的字节序列（UTF-8） |
| 整数 | `number`（统一） | `int` `int8/16/32/64` `uint` | Go 区分整数大小和有无符号 |
| 浮点数 | `number` | `float32` `float64` | Go 默认 `float64` |
| 布尔 | `boolean` | `bool` | 一致 |
| 字符 | 无单独类型 | `rune`（int32 别名） | Go 有「字符」概念，JS 没有 |
| 字节 | 无 | `byte`（uint8 别名） | 处理二进制数据用 |
| 空值 | `null` / `undefined` | `nil` | Go 只有 `nil`，且只能给指针/接口/slice/map 等用 |

**重要：Go 没有 `undefined`。** 一个变量声明了就有零值（见下）。

### 2.4 零值（Zero Value）

JS 中声明未赋值的变量是 `undefined`。Go 中每个类型都有「零值」：

```go
var count int      // 0
var name string    // ""（空字符串，不是 nil）
var flag bool      // false
var p *int         // nil（指针的零值）
```

这避免了 JS 中著名的 `undefined`/`null` 歧义。

### 2.5 类型转换

JS 是动态语言，经常自动转换：`"3" + 2` 得到 `"32"`。Go **绝不自动转换**：

```go
var a int = 3
var b float64 = float64(a)  // 必须显式转换
var c int = int(b)
```

这个「显式」哲学贯穿 Go 始终：**编译器不做任何隐式转换**，所有转换你都得自己写。

---

## 阶段三：流程控制

### 3.1 if 语句

```js
if (age >= 18) {
    console.log("adult");
} else {
    console.log("minor");
}
```

```go
if age >= 18 {          // 不需要括号
    fmt.Println("adult")
} else {
    fmt.Println("minor")
}

// Go 特色：if 可以带一个初始化语句
if age := getAge(); age >= 18 {  // age 只在这个 if 作用域内有效
    fmt.Println("adult")
}
```

**注意：** Go 的 `if` 条件**不能加括号**（加了也能编译，但不推荐），且**必须是布尔值**。JS 中 `if (1)` 会执行，Go 中 `if 1` 直接编译错误。

### 3.2 for 循环（Go 只有 for）

JS 有 `for / while / for...of / for...in`，Go **全部用 `for`**：

```go
// 1. 类 C 的 for
for i := 0; i < 10; i++ {
    fmt.Println(i)
}

// 2. 类 while（省略前后分号）
n := 10
for n > 0 {
    n--
}

// 3. 无限循环
for {
    break
}

// 4. 遍历（类似 for...of）
nums := []int{1, 2, 3}
for index, value := range nums {   // range 类似 for...of 的 entries()
    fmt.Println(index, value)
}

// 遍历 map（类似 for...in）
m := map[string]int{"a": 1}
for key, value := range m {
    fmt.Println(key, value)
}
```

**`range` 对比 JS：**
- `for (const [i, v] of arr.entries())` ≈ `for i, v := range arr`
- 不想用某个返回值，用 `_`（下划线）忽略：`for _, v := range nums`

### 3.3 switch

```js
switch (day) {
    case 1: console.log("Mon"); break;  // JS 必须 break
    case 2:
    case 3: console.log("midweek"); break;
    default: console.log("other");
}
```

```go
switch day {
case 1:
    fmt.Println("Mon")  // Go 默认不穿透，不需要 break！
case 2, 3:              // 多值合并
    fmt.Println("midweek")
default:
    fmt.Println("other")
}

// 想穿透用 fallthrough（很少用）
switch x {
case 1:
    fmt.Println("one")
    fallthrough
case 2:
    fmt.Println("two")
}
```

**最大区别：Go 的 switch 默认不穿透，不用写 `break`。** 这是 Go 设计者认为 JS switch 的 `break` 容易漏写导致 bug，所以反过来默认安全。

Go 的 switch 还能不带表达式，当 `if-else` 链用：
```go
switch {
case age < 18:
    fmt.Println("minor")
case age < 65:
    fmt.Println("adult")
default:
    fmt.Println("senior")
}
```

---

## 阶段四：函数

### 4.1 基本定义

```js
function add(a, b) { return a + b }
const add = (a, b) => a + b;   // 箭头函数
```

```go
func add(a int, b int) int {  // 参数类型 + 返回类型都要写
    return a + b
}

// 相同类型可简写
func add(a, b int) int { return a + b }
```

### 4.2 多返回值（Go 的杀手锏）

JS 只能返回一个值，要多返回只能用数组/对象解构。Go 原生支持多返回值：

```go
func divide(a, b int) (int, int) {
    return a / b, a % b
}

quotient, remainder := divide(17, 5)  // 同时接收两个返回值
quotient, _ := divide(17, 5)           // 不需要余数用 _ 丢弃
```

这个特性直接决定了 Go 的错误处理风格（见阶段九）。

### 4.3 命名返回值

```go
func divide(a, b int) (quotient, remainder int) {  // 返回值提前命名
    quotient = a / b      // 直接赋值，不用声明
    remainder = a % b
    return                 // 裸 return，返回命名的变量
}
```

可读性好但容易出错，新手建议用显式 `return x, y`。

### 4.4 函数是值

JS 里函数是一等公民，能当参数传递。Go 也一样：

```go
func apply(f func(int) int, x int) int {
    return f(x)
}

result := apply(func(n int) int { return n * 2 }, 5)  // 匿名函数
```

类型签名 `func(int) int` 就是函数的类型，类似 TS 的 `(n: number) => number`。

### 4.5 闭包

```js
function counter() {
    let n = 0;
    return () => ++n;
}
```

```go
func counter() func() int {   // 返回一个函数
    n := 0
    return func() int {
        n++
        return n
    }
}
```

概念完全一致：闭包 = 函数 + 它捕获的外层变量。

### 4.6 defer（Go 独有）

`defer` 在函数返回前执行，常用于资源释放：

```go
func readFile() {
    file, err := os.Open("a.txt")
    defer file.Close()   // 不管函数怎么结束，都会执行 Close
    // ... 读文件
}
```

**JS 没有直接对应物**，最接近的是 `try...finally`：
```js
const file = open();
try { /* ... */ } finally { file.close(); }
```

defer 是**后进先出（LIFO）**栈：多个 defer 按相反顺序执行。

---

## 阶段五：集合类型

这是 JS 开发者最容易踩坑的地方，因为 Go 的数组/切片和 JS 数组**形似神不似**。

### 5.1 数组（Array）—— 固定长度

```js
const arr = [1, 2, 3];  // JS 数组长度可变
```

```go
var arr [3]int = [3]int{1, 2, 3}  // Go 数组长度是类型的一部分！
arr[0] = 10
// arr = [4]int{} // 编译错误，长度不同的数组是不同类型
```

**关键：Go 的数组长度固定，且 `[3]int` 和 `[4]int` 是不同的类型。** 实际开发中几乎不用数组，都用切片。

### 5.2 切片（Slice）—— Go 版的「动态数组」

切片才是 Go 里对应 JS `Array` 的东西：

```go
nums := []int{1, 2, 3}       // 注意没有长度数字，就是切片
nums = append(nums, 4)        // 添加元素，类似 arr.push(4)

// make 创建指定容量
s := make([]int, 0, 10)       // 长度0，容量10
```

**底层三要素：** 切片 = 指针 + 长度(len) + 容量(cap)。它是对底层数组的「视图」。

```go
a := [5]int{1, 2, 3, 4, 5}
s := a[1:3]   // 切片，引用 a 的索引1~2，即 [2, 3]
s[0] = 99     // 修改 s 会改到 a！a 变成 [1, 99, 3, 4, 5]
```

**这是和 JS 最大的区别：JS 数组切片会创建副本，Go 切片共享底层数组。** 这是 Go 引用语义的体现，要小心。

**常用操作对照：**

| 操作 | JS | Go |
|------|----|----|
| 创建 | `[1,2,3]` | `[]int{1,2,3}` |
| 追加 | `arr.push(4)` | `arr = append(arr, 4)` |
| 长度 | `arr.length` | `len(arr)` |
| 切片 | `arr.slice(1,3)` | `arr[1:3]`（共享底层数组！） |
| 遍历 | `forEach/map/filter` | 用 `for range` 手写循环 |
| 拼接 | `[...a, ...b]` | `append(a, b...)` |

### 5.3 Map

```js
const obj = { name: "Alice", age: 18 };
const map = new Map([["a", 1]]);
```

```go
// 字面量创建
m := map[string]int{
    "a": 1,
    "b": 2,
}

// make 创建
m := make(map[string]int)
m["a"] = 1

// 读取（注意双返回值）
v, ok := m["a"]   // v=1, ok=true；不存在时 v=0, ok=false
if ok {
    fmt.Println(v)
}

// 删除
delete(m, "a")    // 内置 delete 函数
```

**和 JS 对象的关键区别：**
- Go 的 map 没有「属性访问」语法糖，只能 `m["key"]`。
- Go 的 map key 必须是可比较类型（不能用 slice 当 key）。
- Go 的 map 零值是 `nil`，对 nil map 读返回零值，但**写会 panic**。所以推荐用 `make` 创建。

### 5.4 字符串

```js
"hello".length           // 5
"你好".length             // 2（JS 按 UTF-16 码元算）
```

```go
s := "hello"
len(s)                   // 5（字节数）

s := "你好"
len(s)                   // 6！因为 UTF-8 编码每个汉字3字节

// 想按「字符」遍历，转成 rune 切片
for i, r := range "你好" {  // range 自动按 rune（码点）遍历
    fmt.Println(i, string(r))
}
```

**Go 字符串是不可变的字节序列（UTF-8）。** 修改字符串要转成 `[]byte` 或 `[]rune`。

---

## 阶段六：结构体与方法

Go 没有 class，用 struct + method 模拟面向对象。

### 6.1 定义结构体

```js
class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
}
const p = new Person("Alice", 18);
p.name;  // "Alice"
```

```go
type Person struct {
    Name string   // 大写开头 = 公开（导出），小写 = 私有
    Age  int
}

p := Person{Name: "Alice", Age: 18}  // 按字段名初始化
p.Name                                // "Alice"
```

**导出规则（Go 独有，靠命名大小写）：**
- 字段/函数名**首字母大写** = 对其他包可见（public）
- 首字母小写 = 包内私有（private）
- 没有 `public/private/protected` 关键字！这是 Go 最让 JS 开发者惊讶的设计。

### 6.2 方法（绑定到类型）

```go
func (p Person) Greet() string {   // (p Person) 是「接收者」，类似 JS 的 this
    return "Hi, I'm " + p.Name
}

p.Greet()  // "Hi, I'm Alice"
```

**对比 JS：** Go 的方法接收者像 JS 的 `this`，但要显式写在参数列表里，不像 JS 隐式的 `this`。

### 6.3 指针接收者 vs 值接收者（重要）

```go
// 值接收者：副本，修改不影响原对象
func (p Person) SetAgeValue(a int) { p.Age = a }

// 指针接收者：能修改原对象
func (p *Person) SetAgePointer(a int) { p.Age = a }

p := Person{Name: "Alice", Age: 18}
p.SetAgeValue(20)    // p.Age 还是 18
p.SetAgePointer(20) // p.Age 变成 20
```

**经验法则：** 如果方法要修改对象，或结构体较大，用指针接收者。一个类型的所有方法最好统一用值或指针，别混。

### 6.4 组合优于继承

Go **没有继承**，用「嵌入（embedding）」实现复用：

```go
type Animal struct {
    Name string
}

func (a Animal) Eat() { fmt.Println(a.Name, "is eating") }

type Dog struct {
    Animal          // 嵌入 Animal，Dog 自动获得 Eat() 方法
    Breed string
}

d := Dog{Animal: Animal{Name: "Rex"}, Breed: "Lab"}
d.Eat()            // "Rex is eating"（提升的方法）
d.Name             // "Rex"（提升的字段）
```

**对比 JS：** 类似组合而非继承。Go 的哲学是「组合优于继承」，连 `extends` 都没有。

### 6.5 匿名结构体

```go
p := struct {
    Name string
    Age  int
}{Name: "Bob", Age: 30}   // 一次性结构体，类似 JS 的对象字面量
```

适合临时数据结构，不想专门定义类型时用。

---

## 阶段七：指针

这是 JS 开发者的全新概念（JS 没有显式指针，只有引用类型的隐式传递）。

### 7.1 什么是指针

指针 = 变量的内存地址。

```go
x := 42
p := &x          // & 取地址，p 是 *int 类型（指向 int 的指针）
fmt.Println(*p)  // * 解引用，输出 42
*p = 100         // 通过指针改原变量，x 变成 100
```

### 7.2 值传递 vs 引用传递（关键）

Go 函数参数**全部是值传递**（拷贝一份），没有 JS 那种「对象自动按引用」的行为：

```go
func modify(n int) { n = 100 }   // 改的是副本
x := 1
modify(x)
// x 还是 1
```

要函数能改原变量，传指针：

```go
func modify(n *int) { *n = 100 }
x := 1
modify(&x)
// x 变成 100
```

**对照 JS：** 
- JS 中对象/数组默认按引用传，函数内修改影响外面。
- Go 中即使是 struct/slice/map，函数接收的也是「值的拷贝」，但因为 slice/map 内部含指针，看起来像引用传递（修改元素生效，但替换整个对象不生效）。

**新手记忆口诀：**
- slice、map、channel 像是「自带引用语义」，平时直接传即可。
- struct、int、string 等想被修改，就传指针 `&x`。
- 拿不准时，传指针一般不会错。

### 7.3 new 和 make

```go
p := new(int)      // 返回 *int，指向零值，相当于 &0
s := make([]int, 5)// make 只用于 slice/map/chan，返回初始化好的值
```

JS 没有对应物。简单说：`new` 给基础类型分配并返回指针；`make` 给 slice/map/chan 分配并初始化内部结构。

---

## 阶段八：接口与类型系统

### 8.1 鸭子类型

JS 是动态鸭子类型：「如果它走起来像鸭子，叫起来像鸭子，那它就是鸭子」。

```js
function greet(duck) { console.log(duck.quack()); }  // 只要对象有 quack 方法
```

Go 是**隐式实现的静态鸭子类型**：

```go
type Quacker interface {
    Quack() string
}

type Duck struct{}
func (d Duck) Quack() string { return "Quack!" }

func greet(q Quacker) {   // 参数是接口类型
    fmt.Println(q.Quack())
}

greet(Duck{})   // Duck 满足 Quacker 接口，自动通过
```

**核心：Go 不需要 `implements` 关键字！** 只要类型实现了接口定义的所有方法，就算实现了接口。这叫「隐式接口」。

对比 TS 的 `interface`：
```ts
interface Quacker { quack(): string }
// TS 用结构类型，和 Go 接口哲学接近，但 Go 是编译期检查
```

### 8.2 空接口 interface{}

Go 1.18 前的「任意类型」用空接口：

```go
func print(v interface{}) {   // 空接口，任何类型都能传
    fmt.Println(v)
}
```

类似 JS 的「无类型约束的参数」。Go 1.18+ 推荐用 `any`（就是 `interface{}` 的别名）：

```go
func print(v any) { fmt.Println(v) }
```

### 8.3 类型断言与 type switch

因为接口里存的是动态类型，取出时需要「断言」：

```go
var i interface{} = "hello"

s := i.(string)         // 类型断言，不是 string 会 panic
s, ok := i.(string)      // 安全形式，ok 表示是否成功

// type switch（类似 JS 的 typeof 判断）
switch v := i.(type) {
case string:
    fmt.Println("string", v)
case int:
    fmt.Println("int", v)
default:
    fmt.Println("unknown")
}
```

**和 JS 对比：** JS 用 `typeof`/`instanceof`，运行时判断；Go 用类型断言，编译时就有类型保障。

### 8.4 类型别名与类型定义

```go
type MyInt int          // 类型定义，MyInt 是新类型，和 int 不能直接运算
type Score = int        // 类型别名（= 号），Score 就是 int 本身
```

---

## 阶段九：错误处理

这是 Go 和 JS 哲学差异最大的地方之一。

### 9.1 没有异常，用返回值

JS 用 `try/catch/throw`：

```js
function divide(a, b) {
    if (b === 0) throw new Error("divide by zero");
    return a / b;
}
try {
    divide(1, 0);
} catch (e) {
    console.error(e);
}
```

Go 把错误当**普通返回值**（依赖多返回值特性）：

```go
func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, errors.New("divide by zero")   // 返回错误
    }
    return a / b, nil
}

result, err := divide(10, 0)
if err != nil {              // Go 最常见的判断模式
    fmt.Println(err)
    return
}
fmt.Println(result)
```

**`error` 是个接口**，约定：成功返回 `nil`，失败返回非 nil 的 error。这种 `if err != nil` 在 Go 代码里随处可见。

### 9.2 自定义错误

```go
// 实现 Error() string 方法的类型就是 error
type MyError struct {
    Code int
    Msg  string
}
func (e *MyError) Error() string {
    return fmt.Sprintf("code %d: %s", e.Code, e.Msg)
}
```

### 9.3 错误包装（Go 1.13+）

```go
if err := doSomething(); err != nil {
    return fmt.Errorf("operation failed: %w", err)  // %w 包装错误，保留链
}
```

用 `errors.Is` 和 `errors.As` 判断/解包：
```go
if errors.Is(err, os.ErrNotExist) { /* 文件不存在 */ }
var myErr *MyError
if errors.As(err, &myErr) { /* 是自定义错误 */ }
```

### 9.4 panic / recover（慎用）

Go 也有类似 throw 的机制，但**只用于真正的不可恢复错误**：

```go
func risky() {
    defer func() {
        if r := recover(); r != nil {   // 捕获 panic
            fmt.Println("recovered:", r)
        }
    }()
    panic("boom")   // 类似 throw
}
```

**原则：** 99% 的情况用 `error` 返回值。panic 只在「程序状态已损坏，无法继续」时用（如数组越界、nil 解引用）。库的 API 不要 panic。

---

## 阶段十：并发编程

这是 Go 的王牌特性，也是 JS 开发者需要转换思维的地方。

### 10.1 思维对照

| 维度 | JavaScript | Go |
|------|-----------|----|
| 并发模型 | 单线程 + 事件循环 | 多协程 + 调度器 |
| 异步写法 | `async/await`、Promise、回调 | `go func()` 直接并发 |
| 通信方式 | 共享变量、事件 | **「不要靠共享内存通信，要靠通信共享内存」** |
| 阻塞 | 异步非阻塞 | 协程阻塞不影响其他协程 |

JS 是「单线程异步」，Go 是「真多协程并发」。

### 10.2 Goroutine（轻量线程）

```go
go sayHello()   // 启动一个 goroutine 执行 sayHello

go func() {     // 匿名函数 goroutine
    fmt.Println("running in goroutine")
}()
```

类似 JS 里 `setTimeout(fn, 0)` 或开一个 Promise，但 goroutine 是真正的并发执行单位，开销极小（几 KB）。

**注意：** 主函数 main 不会等 goroutine。常见坑是 main 结束了 goroutine 还没跑完，程序就退出了。

### 10.3 Channel（通道）

goroutine 之间靠 channel 通信：

```go
ch := make(chan int)  // 无缓冲通道

go func() {
    ch <- 42          // 发送（会阻塞，直到有人接收）
}()

v := <-ch            // 接收（会阻塞，直到有数据）
fmt.Println(v)
```

**缓冲通道：**
```go
ch := make(chan int, 3)   // 缓冲大小3
ch <- 1   // 不阻塞，直到缓冲满
ch <- 2
ch <- 3
// ch <- 4  // 缓冲满了，阻塞
```

**对照 JS：** channel 像一个「同步队列」，类似手写一个 Promise + 事件组合，但 channel 天然处理并发同步。

### 10.4 select（多路复用）

```go
select {
case v := <-ch1:
    fmt.Println("from ch1:", v)
case v := <-ch2:
    fmt.Println("from ch2:", v)
case <-time.After(time.Second):
    fmt.Println("timeout")   // 类似 Promise.race
default:
    fmt.Println("无数据")    // 非阻塞
}
```

类似 `Promise.race`：哪个 channel 先就绪就执行哪个。

### 10.5 sync 包（传统同步原语）

```go
var wg sync.WaitGroup
wg.Add(1)
go func() {
    defer wg.Done()    // 类似计数器，通知完成
    // do work
}()
wg.Wait()             // 等待所有 goroutine 结束
```

```go
var mu sync.Mutex
mu.Lock()
// 临界区
mu.Unlock()           // 类似加锁
```

**新手建议：** 先学 channel，它是 Go 的惯用法。需要保护共享内存时才用 Mutex。

### 10.6 并发的常见陷阱

```go
// ❌ 闭包捕获循环变量（Go 1.22 前的经典坑）
for i := 0; i < 3; i++ {
    go func() { fmt.Println(i) }()  // 可能打印同一个 i！
}

// ✅ 传参
for i := 0; i < 3; i++ {
    go func(i int) { fmt.Println(i) }(i)
}
```

> Go 1.22+ 修复了循环变量捕获问题，每个迭代有独立变量，但理解原理仍重要。

---

## 阶段十一：工程化

### 11.1 包与导入

```
myproject/
├── go.mod
├── main.go
├── user/
│   └── user.go       // package user
└── auth/
    └── auth.go       // package auth
```

```go
package main

import (
    "fmt"
    "myproject/user"      // 导入本地包
    "github.com/gin-gonic/gin"  // 导入第三方
)
```

**对比 JS：**
- 一个文件夹 = 一个包（不像 JS 一个文件一个模块）。
- 包名一般和文件夹名一致。
- 导入路径是完整路径，不是相对路径的 `./`（相对路径只在模块内）。

### 11.2 go mod（依赖管理）

```bash
go mod init myproject          # 类似 npm init
go get github.com/gin-gonic/gin  # 类似 npm install
go mod tidy                    # 清理/补全依赖
```

`go.mod` 文件类似 `package.json`，`go.sum` 类似 `package-lock.json`。

### 11.3 测试

Go 测试是**内置的**，不需要 Jest：

```go
// 文件名必须以 _test.go 结尾，函数以 Test 开头
// math_test.go
package math

import "testing"

func TestAdd(t *testing.T) {
    got := Add(1, 2)
    want := 3
    if got != want {
        t.Errorf("Add(1,2) = %d, want %d", got, want)
    }
}
```

```bash
go test ./...     # 跑所有测试，类似 npm test
go test -v        # 详细输出
go test -cover    # 覆盖率
```

**表驱动测试（Go 惯用法）：**
```go
func TestAdd(t *testing.T) {
    cases := []struct {
        a, b, want int
    }{
        {1, 2, 3},
        {0, 0, 0},
        {-1, 1, 0},
    }
    for _, c := range cases {
        if got := Add(c.a, c.b); got != c.want {
            t.Errorf("Add(%d,%d)=%d, want %d", c.a, c.b, got, c.want)
        }
    }
}
```

### 11.4 基准测试与示例

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(1, 2)
    }
}  // go test -bench=.
```

### 11.5 项目布局建议

Go 官方有个参考布局 `golang-standards/project-layout`，但新手别纠结，简单项目这样即可：

```
myapp/
├── go.mod
├── cmd/
│   └── myapp/
│       └── main.go      # 入口
├── internal/            # 只能本模块导入（Go 编译器强制私有）
│   └── service/
└── pkg/                 # 可被外部导入的公共库
```

`internal/` 目录是 Go 特有的：编译器禁止其他模块导入它，天然实现「私有包」。

---

## 阶段十二：进阶专题

### 12.1 泛型（Go 1.18+）

```js
// TS 泛型
function first<T>(arr: T[]): T { return arr[0] }
```

```go
func First[T any](arr []T) T {
    return arr[0]
}

First[int]([]int{1, 2, 3})    // 显式类型参数
First([]string{"a", "b"})     // 可省略，自动推断
```

语法和 TS 思路接近，用 `[T any]` 声明类型参数。`any` 是类型约束（即 `interface{}`）。

**类型约束：**
```go
type Number interface {
    int | int64 | float64   // 联合类型，类似 TS 的 |
}

func Sum[T Number](nums []T) T { /* ... */ }
```

Go 1.18 起内置了 `comparable` 约束，标准库 `golang.org/x/exp/constraints` 有更多。

### 12.2 context（上下文）

Go 后端必备，用于超时/取消/传值：

```go
func handler(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
    defer cancel()

    result, err := doQuery(ctx, "SELECT ...")
    // doQuery 内部要监听 ctx.Done()，超时则提前返回
}
```

**没有直接 JS 对应物**，最接近的是 `AbortController`，但 context 更强大（带值传递、超时、取消链）。

**规则：** 函数第一个参数约定传 `ctx context.Context`，尤其涉及 I/O（DB、HTTP、RPC）的函数。

### 12.3 反射（reflect）

```js
typeof x        // "number"
obj instanceof Class
```

```go
import "reflect"
t := reflect.TypeOf(x)
v := reflect.ValueOf(x)
```

能用但慢，且降低类型安全。**Go 哲学：能不用反射就不用。**

### 12.4 常用标准库速览

| 用途 | JS | Go 标准库 |
|------|----|---------|
| HTTP 服务 | express/koa | `net/http` |
| JSON | `JSON.parse/stringify` | `encoding/json` |
| 字符串 | 内置方法 | `strings` `strconv` |
| 时间 | `Date` | `time` |
| 文件 I/O | `fs` | `os` `io` `bufio` |
| 正则 | `RegExp` | `regexp` |
| 随机数 | `Math.random` | `math/rand` `crypto/rand` |
| 加密 | crypto 模块 | `crypto/*` |

### 12.5 JSON 处理

```js
const obj = JSON.parse(str);
const str = JSON.stringify(obj);
```

```go
type User struct {
    Name string `json:"name"`   // 结构体标签，类似注解
    Age  int    `json:"age"`
}

var u User
json.Unmarshal([]byte(str), &u)   // 反序列化
data, _ := json.Marshal(u)        // 序列化
```

**和 JS 区别：** Go 用结构体字段标签映射 JSON key，字段必须大写（导出）才能被序列化，小写字段会被忽略。

### 12.6 init 函数

```go
package main

func init() {
    // 每个包的 init 在 main 之前自动执行，用于初始化
    // 类似「模块加载时的副作用」
}

func main() { /* ... */ }
```

类似 JS 模块顶层代码，但 Go 有专门的 `init()` 函数，每个文件可有多个，按顺序执行。

---

## 附录：Go vs JS 速查表

### 声明

| 用途 | JS | Go |
|------|----|----|
| 可变变量 | `let x = 1` | `var x = 1` 或 `x := 1`（函数内） |
| 常量 | `const x = 1` | `const x = 1` |
| 函数 | `function f(){}` | `func f(){}` |
| 箭头函数 | `(a) => a+1` | `func(a int) int { return a+1 }` |

### 类型

| JS | Go |
|----|----|
| `number` | `int` / `float64` |
| `string` | `string`（字节序列） |
| `boolean` | `bool` |
| `null/undefined` | `nil`（仅限指针/接口/slice/map） |
| `Array` | `[]T`（切片） |
| `Object` | `map[string]T` 或 `struct` |
| `class` | `struct` + 方法 |
| `any` | `any`（= `interface{}`） |

### 控制流

| JS | Go |
|----|----|
| `if/else` | `if/else`（条件不加括号，必须 bool） |
| `for/while/for..of/in` | 全用 `for` + `range` |
| `switch`（要 break） | `switch`（默认不穿透） |
| `try/catch/finally` | `error` 返回值 + `defer` |
| `throw` | `panic`（慎用） |

### 并发

| JS | Go |
|----|----|
| `Promise` | goroutine + channel |
| `async/await` | `go func()` + `<-ch` |
| `Promise.all` | `select` / `sync.WaitGroup` |
| `Promise.race` | `select` + `time.After` |
| `AbortController` | `context.Context` |

### 工程化

| JS | Go |
|----|----|
| `package.json` | `go.mod` |
| `package-lock.json` | `go.sum` |
| `npm install` | `go get` |
| `npm test`（Jest） | `go test`（内置） |
| `node_modules` | `$GOPATH/pkg/mod`（全局缓存） |
| `import` | `import`（路径式） |
| Prettier | `gofmt`（内置） |
| ESLint | `go vet` + `golangci-lint` |

---

## 学习路线建议

1. **第 1 周**：环境搭建、基本语法、流程控制。把本笔记阶段一到三跑一遍，写几个小练习（斐波那契、九九乘法表）。
2. **第 2 周**：函数、切片、map、struct。重点吃透「切片共享底层数组」「指针」「导出大小写」三个概念。
3. **第 3 周**：接口、错误处理。理解 `if err != nil` 为何是 Go 文化，写个读文件的小工具。
4. **第 4 周**：goroutine + channel，写个并发下载或 worker pool。
5. **第 5 周起**：用 `net/http` 写一个 REST API，连数据库，体会 context、JSON、测试。

**推荐资源：**
- 官方教程 [A Tour of Go](https://go.dev/tour/)
- [Effective Go](https://go.dev/doc/effective_go)
- [Go by Example](https://gobyexample.com/)
- 书籍《Go 程序设计语言》（The Go Programming Language）

> 核心心法：**显式优于隐式、组合优于继承、简单优于复杂、通信优于共享。** 这四句话贯穿 Go 设计始终，理解了它们就理解了 Go。
