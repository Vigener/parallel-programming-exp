// ============================================================
// template.typ
//  五十嵐尊人 専用 レポートテンプレート
// ============================================================

#let report(
  title: "",
  subtitle: "",
  show-toc: true,
  toc-title: [目次],
  toc-depth: 2,
  author: "五十嵐 尊人",
  student-id: "202310970",
  department: "筑波大学 情報科学類",
  date: datetime.today().display("[year]年[month]月[day]日"),
  body
) = {

  // --------------------------------------------------------
  // 1. 文書の基本設定
  // --------------------------------------------------------
  set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))
  set text(
    lang: "ja",
    size: 11pt,
    font: ("New Computer Modern", "Hiragino Mincho ProN", "Noto Serif CJK JP")
  )
  set par(
    justify: true,
    leading: 0.65em,
    first-line-indent: 1em
  )

  // --------------------------------------------------------
  // 2. 見出し・数式・図表の番号付け（Typst標準機能を利用）
  // --------------------------------------------------------
  set heading(numbering: "1.1.")
  
  // 数式に自動で (1), (2) と番号を振る
  set math.equation(numbering: "(1)")
  
  // 通常リンクを青 + 下線にして、視認しやすくする
  show link: it => {
    underline(text(fill: rgb("#0b57d0"))[#it])
  }

  // 図表参照（@label）は青のみ（下線なし）にして、Webリンクと見分けやすくする
  // `ref` をそのまま残して文字色だけ変えることで、参照のクリック機能を維持する。
  show ref: set text(fill: rgb("#2f5ea8"))

  // --------------------------------------------------------
  // 3. コードブロックの装飾（尊人さんの設定2を完全統合）
  // --------------------------------------------------------
  // ブロックコード
  show raw.where(block: true): it => block(
    fill: rgb("#f8f9fa"),
    width: 100%,
    inset: 12pt,
    radius: 6pt,
    stroke: rgb("#e9ecef"),
    {
      if it.lang != none {
        place(
          top + right,
          text(fill: rgb("#adb5bd"), size: 8pt, weight: "bold", it.lang)
        )
      }
      text(font: ("JetBrains Mono", "Consolas", "Courier New", "Menlo"), size: 9.5pt, it)
    }
  )

  // インラインコード
  show raw.where(block: false): it => box(
    fill: rgb("#f8f9fa"),
    inset: (x: 4pt, y: 0pt),
    outset: (y: 3pt),
    radius: 3pt,
    text(font: ("JetBrains Mono", "Consolas", "Courier New", "Menlo"), it)
  )

  // --------------------------------------------------------
  // 4. タイトルページの生成
  // --------------------------------------------------------
  align(center)[
    #v(2em)
    #text(size: 20pt, weight: "bold")[#title]
    #if subtitle != "" {
      v(0.5em)
      text(size: 14pt)[#subtitle]
    }
    #v(3em)
    #text(size: 12pt)[所属: #department] \
    #if student-id != "" { text(size: 12pt)[学籍番号: #student-id \ ] }
    #text(size: 12pt)[氏名: #author] \
    #v(1em)
    #text(size: 12pt)[作成日: #date]
  ]

  v(2em)

  if show-toc {
    outline(title: toc-title, depth: toc-depth)
    pagebreak()
  }

  // --------------------------------------------------------
  // 5. 本文の展開
  // --------------------------------------------------------
  body
}