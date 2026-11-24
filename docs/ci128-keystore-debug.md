# CI #128 密钥库诊断步骤（docs/ci128-keystore-debug.md）

## 背景：三次失败，三种不同的报错

仓库 xinyonghuu/maoyingshi，工作流 `.github/workflows/b8-c0.yml`，分支
`b8-flutter-rewrite`，head `f7b58ec4`。Run #128 在第 15 步
"Build four release APKs"（`:app:packageMobileArm64_v8aRelease`）失败了三次，
每次都是签名读密钥失败，但报错各不相同：

- **第 1、2 次**（OpenSSL 3 生成的 PKCS12 密钥库，别名 `maoyingshi`）：
  `KeytoolException: Failed to read key *** from store ".../app/signing/release.jks": null`
  本机验证结论：`getKey` 只有在别名错误时才返回 NULL（口令错、库损坏会报别的错）。
- **第 3 次**（keytool 生成的 JKS 密钥库，同一别名、同一口令）：
  `KeytoolException: Failed to read key *** from store "...": DerInputStream.getLength(): lengthTag=109, too big`
  本机验证结论：口令错、别名错、库口令错、PKCS12 损坏、PKCS12 截断，各自产生的
  报错都与这个 DER 错误不同，没有一个是它。

## 本机已证明的事实

- 两个密钥库文件在本机 JDK 21 下全部正常：加载、别名、`getKey` 均通过，
  JKS 类型和默认 PKCS12 类型下都通过。
- 仓库里只有 3 个 Secret（列表核实过，无多余 Secret）：
  `RELEASE_KEYSTORE_BASE64`、`RELEASE_KEY_ALIAS`、`RELEASE_STORE_PASSWORD`。
- 本机密钥库文件的 SHA-256（供与 CI 输出比对）：
  - `release.p12`（第 1、2 次用的 OpenSSL PKCS12）：
    `7946a45c2cacc15662b9c9f3a2d41a49bbc73e5a11395b92274917740ab67527`
  - `release.jks`（第 3 次用的 keytool JKS，当前 Secret 应为此文件）：
    `95e8865c51b4a0d11ef6af4a19884e7dd4ad5c9542190fa2b55e73ead48b7d8e`
  - 已核实 `release_base64.txt` 解码后等于 `release.p12`，
    `release_jks_base64.txt` 解码后等于 `release.jks`。

## 唯一未知的环节

CI 里实际解码出来的文件。Secret 的 base64 值是经浏览器粘贴进仓库的，
CI 解码得到的文件可能与本机文件不一致——这是三次失败都无法用本机
测试复现时，剩下的唯一未知数。

## 本次改动：只加一个诊断步骤

在 "Configure release signing" 之后、"Build four release APKs" 之前新增：

```yaml
- name: Verify decoded keystore (debug)
  env:
    RELEASE_STORE_PASSWORD: ${{ secrets.RELEASE_STORE_PASSWORD }}
  run: |
    sha256sum app/signing/release.jks
    keytool -list -keystore app/signing/release.jks -storepass "$RELEASE_STORE_PASSWORD" || true
    keytool -list -keystore app/signing/release.jks -storetype JKS -storepass "$RELEASE_STORE_PASSWORD" || true
```

- `sha256sum`：与上节本机哈希比对，判断 CI 解码的文件是否就是本机文件。
- 第一个 `keytool -list`（默认类型）：显示密钥库类型、别名、条目类型
  （应为 `maoyingshi` / `PrivateKeyEntry`）。
- 第二个 `keytool -list -storetype JKS`：判断文件是否能按 JKS 读出。
- `|| true`：诊断失败不中断后续构建步骤，让打包步骤照常跑，
  这样一次运行同时拿到诊断输出和打包结果。
- 不打印任何 Secret 值：库口令只经环境变量传入，从不 echo；
  GitHub 会在日志里自动掩码 Secret 值。

## 如何读下一次运行的结果

| CI 输出 | 结论 |
| --- | --- |
| sha256 = `95e8865c…`（与本机 `release.jks` 一致），`-list` 正常 | 解码文件无损，Secret 值没问题；问题在打包侧对密钥库的使用方式 |
| sha256 与本机两个哈希都不一致 | Secret 里的 base64 值与本机文件不符（粘贴损坏或传错了文件），需重新录入 |
| sha256 = `7946a45c…`（本机 `release.p12`） | Secret 里仍是旧的 PKCS12 文件，第 3 次的 JKS 更新没生效 |
| `-list`（默认类型）失败，`-storetype JKS` 成功 | 文件是 JKS，但默认类型读不出来——类型判断问题 |
| 两个 `-list` 都失败 | 解码出的文件根本不是有效密钥库 |
| `-list` 正常但打包仍报 DER 错误 | 密钥库本身没问题，错误来自打包步骤读取密钥的方式，需看打包日志 |

## 备注

- 本步骤是临时诊断，找到根因后应删掉。
- 本次改动只动了工作流文件和本文档，未改签名步骤、构建步骤和其他任何文件。
- 本地无法验证该步骤（无 CI 运行），下一次 CI 运行即为验证。
