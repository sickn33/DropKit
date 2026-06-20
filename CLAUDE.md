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

- 这是**已上架 App Store** 的真实应用项目。发布、打 tag、替换 `/Applications/DropKit.app`、提交审核 / 分发相关动作都必须先得到用户明确确认。
- 修改前先看 `CHANGELOG.md`、当前 git 分支和未提交改动。
- 不要动 `DropKit/.claude/settings.local.json`;它是本机权限状态,不是项目规范。
- 菜单栏图标、拖拽暂存架、剪贴板历史、摇晃唤出暂存架是核心验收面。摇晃手势现用普通全局鼠标事件实现(**不再需要辅助功能权限**,为修 2.4.5 已移除全部 Accessibility 用法)。构建通过后仍需要在真实 App 上手动验证关键路径。

## 分发现状(2026-06 已上架)

- **已上架 Mac App Store**:商店名 **DropKit Clipboard**,App ID `6778846792`,商店链接 https://apps.apple.com/app/dropkit-clipboard/id6778846792 。当前 Marketing 版本 `1.0.6` / Build `1.0.7`,状态 READY_FOR_SALE。
- **发布方式 = AFTER_APPROVAL**:审核通过后自动上架,**无需手动点"发布"**。
- **分发自动化**:App Store Connect API 密钥在 `密钥存储/`(`AuthKey_6WFT7RNHGK.p8` + `.env.appstoreconnect`,Key ID `6WFT7RNHGK`,Issuer `360b4d1b-…`)。本机无 fastlane,但有 Python `cryptography`,可手搓 ES256 JWT 调 `api.appstoreconnect.apple.com` 查状态 / 选 build / 改元数据 / 提交审核。
- **分工**:小陈不熟 App Store Connect 网页操作,**以后版本更新的打包+上传+提交分发,由 Claude 用上面这套 API 代劳**(只有 Resolution Center 回复审核员需手动贴)。
- **GitHub**:只留源码 / Issue,不再做 GitHub 分发。`README` 里"源码构建为唯一安装方式""需要辅助功能权限"等说法在上架 + 移除 Accessibility 后已过时,需同步更新。
