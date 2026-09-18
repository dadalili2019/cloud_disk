# Personal Workbench UI / UX 设计规范

## 1. 设计目标

当前 UI 目标：

- 长时间使用舒适
- 信息密度适中
- 不用大面积纯白
- 不用荧光强调色
- 少说明文字
- 不重复标题
- 桌面端优先
- 小窗口可响应

## 2. Global Shell

### Topbar

高度约 54px。

组成：

~~~text
Brand
Workspace Switcher
Global Search
AI
Settings
Window Controls
~~~

### Sidebar

普通宽度约 224px。

窗口较窄时进入 compact 模式，仅保留图标。

一级导航：

~~~text
首页
工作区
时间

工作台
知识
开发者
工具

设置
~~~

## 3. Workspace Shell

Workspace 内部使用顶部二级导航：

~~~text
概览 任务 笔记 问题 资源 决策 开发
~~~

当前 section 采用低亮度绿色强调。

## 4. 页面层级

避免：

- 大号 Page Title
- 页面说明段落
- 重复的“当前模块”标题
- 为零数据创建巨大空卡

推荐：

~~~text
Section Header
→ Content
→ Action
~~~

## 5. 间距基线

当前 Workbench 常用基线：

- 页面水平留白：约 24–40
- 页面顶部：约 18
- 卡片默认 padding：约 20
- 卡片间距：约 12–18
- 大区块：约 18–24

不要为了“紧凑”把所有元素压到一起。

## 6. 色彩

当前默认视觉：

- Comfort Dark
- 深灰背景
- 中灰卡片
- 柔和绿 Accent
- Microsoft YaHei UI

强调色只用于：

- 当前选中
- 主操作
- 状态
- 少量标签

避免使用大面积绿色背景。

## 7. Home

Home 不显示大标题。

主卡优先级：

1. Current Task
2. Next Step
3. Blocker
4. Progress
5. Last Context

Today / Recent Activity 为次级区域。

## 8. Drawer

主要 Drawer：

- Quick Capture
- Continue
- Global AI

原则：

- 固定右侧打开
- 不遮挡整个应用
- 标题紧凑
- 操作区清晰
- 不重复解释行为

## 9. Dialog

Dialog 用于：

- 新建 / 编辑
- 危险操作确认
- Restore
- Knowledge Distill

桌面表单尽量采用两列，避免从上到下长表单。

操作按钮默认右对齐：

~~~text
取消  保存
~~~

## 10. Empty State

只表达状态，不解释产品。

推荐：

- 暂无
- 暂无任务
- 暂无动态
- 暂无安排

避免：

- “创建一个工作区后，你可以……”
- “这里将帮助你……”

## 11. Responsive

关键断点并非固定设计系统 token，而是当前实现中的经验值：

- Shell compact：约 1000px
- Topbar 隐藏部分 controls：约 820 / 1040px
- Card Grid：按 1 / 2 / 3 列自适应

小窗口优先保证：

- 无横向溢出
- 操作按钮可换行
- 表单回退到单列
- Drawer 内容可滚动
