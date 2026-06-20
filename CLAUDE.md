# CLAUDE.md

`DropKit/` 是独立 macOS 菜单栏 App 项目。进入实际工程前先 `cd DropKit/` 并读里面的 `README.md` 与 `project.yml`。

## 常用命令

```bash
cd /Users/chenhuajin/项目/自己的应用/DropKit/DropKit
xcodegen generate
xcodebuild -scheme DropKit -configuration Release build
xcodebuild -scheme DropKit test
```

## 硬规则

- 这是 App Store 迁移中的真实应用项目。发布、打 tag、替换 `/Applications/DropKit.app`、提交审核相关动作都必须先得到用户明确确认。
- 修改前先看 `CHANGELOG.md`、当前 git 分支和未提交改动。
- 不要动 `DropKit/.claude/settings.local.json`;它是本机权限状态,不是项目规范。
- Accessibility 权限、菜单栏图标、拖拽暂存架、剪贴板历史是核心验收面。构建通过后仍需要在真实 App 上手动验证关键路径。
