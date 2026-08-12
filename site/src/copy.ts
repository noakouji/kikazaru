// サイトの文言。構造を1つに保ったまま日英を切り替えるため、ここに集約する。
// 翻訳調にならないよう、英語は直訳ではなく英語として自然な言い回しにしている。

export type Lang = 'ja' | 'en'

export interface Copy {
  lang: Lang
  htmlLang: string
  altHref: string
  altLabel: string
  meta: { title: string; description: string }
  nav: { download: string }
  hero: {
    tagline: string
    sub: string
    download: string
    meta: string
    note: [string, string, string]
  }
  shot: { heading: string; body: string; fine: string; alt: string; image: string }
  problem: {
    label: string
    heading: string
    want: string
    before: string
    after: string
    musicLoud: string
    musicDown: string
    talking: string
    transcript: string
    dirty: string
    dirtyMark: string
    clean: string
    beforeList: [string, string, string]
    afterList: [string, string, string]
    causeHeading: string
    causeLead: [string, string, string]
    okMark: string
    ngMark: string
    okName: string
    okNote: string
    ngName: string
    ngNote: string
    causeTail: [string, string]
  }
  steps: {
    label: string
    heading: string
    items: { emoji: string; title: string; body: string }[]
    tail: string
  }
  speakers: {
    label: string
    heading: string
    rows: { name: string; note: string; state: string }[]
    tail: string
  }
  why: { label: string; heading: string; body: [string, string, string] }
  install: {
    label: string
    heading: string
    intro: string
    calloutMain: [string, string, string]
    calloutSub: string
    steps: { title: string; body: string; figure?: string; key?: boolean }[]
    afterHeading: string
    afterBody: [string, string]
    afterFine: string
    troubleHeading: string
    troubleBody: [string, string, string]
    troubleLink: string
    troubleTail: [string, string]
  }
  support: {
    label: string
    heading: string
    bugTitle: string
    bugBody: string
    bugBtn: string
    kofiTitle: string
    kofiBody: string
    kofiBtn: string
    kofiFallback: string
  }
  foot: { made: string; install: string; support: string; copy: string }
  page: {
    title: string
    description: string
    back: string
    heading: string
    lead: string
    moneyHeading: string
    moneyBody: string
    moneyList: { icon: string; title: string; note: string; cost: string }[]
    payHeading: string
    payNote: string
    otherHeading: string
    otherBody: string
    otherList: { icon: string; title: string; body: string }[]
    closing: string
  }
}

export const ja: Copy = {
  lang: 'ja',
  htmlLang: 'ja',
  altHref: '/en',
  altLabel: 'English',
  meta: {
    title: 'Kikazaru — マイクがオンの間だけ、部屋のBGMを下げる Mac アプリ',
    description:
      '音声入力やオンライン会議のあいだ、Sonos や Google Home の音量を自動で下げます。話し終わると元に戻ります。macOS 用・無料。',
  },
  nav: { download: 'ダウンロード' },
  hero: {
    tagline: 'マイクがオンの間だけ、<br />部屋のBGMを下げる',
    sub: '音声入力やオンライン会議の間、Sonos や Google Home の音量を下げます。話し終われば元に戻ります。',
    download: 'Kikazaru をダウンロード',
    meta: 'macOS 14 以降 / 無料 / 約 400 KB',
    note: ['ダウンロードしたあと、', '初回だけひと手間かかります', '。1分で終わります。'],
  },
  shot: {
    heading: '設定はこれだけ',
    body: '同じネットワークにあるスピーカーが自動で並びます。**下げたいものにチェックを入れれば終わり**で、IPアドレスの入力なども要りません。',
    fine: 'Sonos 以外は、うっかりテレビを下げてしまわないよう初期状態ではオフです。アプリごとに「下げる／ミュートする」を選ぶこともできます。',
    alt: 'Kikazaru の設定画面。見つかったスピーカーが並び、下げたいものにチェックを入れる',
    image: '/app-settings.png',
  },
  problem: {
    label: 'やりたいこと',
    heading: '音楽は流したまま、喋って仕事したい',
    want: '作業中は音楽をかけておきたい。でも音声入力もオンライン会議も使う。いまはどちらかを諦めるしかありません。',
    before: 'いままで',
    after: 'Kikazaru を入れると',
    musicLoud: '音楽が大きいまま',
    musicDown: '喋る間だけ自動で下がる',
    talking: '喋る',
    transcript: '文字起こし',
    dirty: '議事録から箇条書きにして',
    dirtyMark: '君と歩いた あの日の',
    clean: '議事録から箇条書きにして',
    beforeList: ['音楽をいちいち止める', 'ヘッドホンに付け替える', '会議相手にも音楽が流れる'],
    afterList: ['音楽は流したままでいい', 'ヘッドホンは要らない', '話し終われば元の音量に戻る'],
    causeHeading: 'なぜ勝手に止まらないのか',
    causeLead: ['音声入力アプリも音を下げてはくれます。ただし止められるのは', 'Mac につないだスピーカーだけ', 'です。'],
    okMark: '自動で下がる',
    ngMark: '下がらない',
    okName: 'Mac につないだスピーカー',
    okNote: 'Bluetooth・USB・AirPlay など',
    ngName: 'Sonos / Google Home',
    ngNote: 'スピーカー自身が鳴らしているため',
    causeTail: [
      'Sonos や Google Home は、Mac ではなくスピーカー自身が音楽を再生しています。Mac はその音を握っていないので、止めようがありません。',
      'その隙間だけを埋めます。',
    ],
  },
  steps: {
    label: '動き',
    heading: '入れたあとは何もしません',
    items: [
      { emoji: '🎙', title: '話し始める', body: 'マイクがオンになったことを検知します' },
      { emoji: '🙉', title: 'BGMが下がる', body: '約0.1秒でスピーカーの音量を下げます' },
      { emoji: '🐵', title: '話し終わる', body: '元の音量にそのまま戻します' },
    ],
    tail: 'メニューバーの絵文字が 🐵 と 🙉 で切り替わるので、いま下がっているかどうかが一目で分かります。待機中は何も動かないので、電池もほとんど食いません。',
  },
  speakers: {
    label: '対応スピーカー',
    heading: 'ネットワーク上のスピーカーを自動で探します',
    rows: [
      { name: 'Sonos', note: '推奨。実機で確認済み', state: 'ok' },
      { name: 'Google Home / Chromecast', note: '実機で確認済み', state: 'ok' },
      { name: 'Bose SoundTouch', note: '実機がないため未確認', state: 'wip' },
      { name: 'Mac から鳴らしているスピーカー', note: '設定で有効にできます', state: 'sub' },
    ],
    tail: 'IPアドレスの入力は要りません。Sonos 以外は、うっかりテレビを下げてしまわないよう初期状態ではオフになっています。設定でチェックを入れると有効になります。',
  },
  why: {
    label: 'なぜ作ったか',
    heading: '打つより喋るほうが速い場面が増えた',
    body: [
      'AI に指示を出すのも、議事録をまとめるのも、打つより喋るほうが速い。一日中そうしていると、スピーカーの音がマイクに入るのが毎回引っかかります。',
      'そのたびに音楽を止めたり、ヘッドホンに付け替えたりするのが面倒で作りました。',
      '入れておけば、音楽は流したままで済みます。',
    ],
  },
  install: {
    label: 'インストール',
    heading: 'はじめの5ステップ',
    intro: '全部で1分ほどです。3つめだけ、ふつうと違うので気をつけてください。',
    calloutMain: [
      'Kikazaru は Apple に開発元の登録をしていない個人アプリです。そのままダブルクリックすると',
      '「開発元を検証できないため開けません」',
      'と出て止まります。壊れているわけではありません。',
    ],
    calloutSub: '個人が作って配っているだけなので、こうなっています。ここだけすみません。',
    steps: [
      { title: 'ダウンロードした Kikazaru.zip をダブルクリックする', body: '同じ場所に Kikazaru.app が出てきます。' },
      { title: 'Kikazaru.app を「アプリケーション」フォルダへ移す', body: '必須ではありませんが、入れておくと迷子になりません。' },
      {
        title: 'アイコンを右クリックして「開く」を選ぶ',
        body: 'ここが唯一のコツです。ダブルクリックでは開けません。トラックパッドなら二本指クリック、または control キーを押しながらクリックでも同じです。',
        figure: 'contextMenu',
        key: true,
      },
      {
        title: '確認の画面で、もう一度「開く」を押す',
        body: 'これで許可されます。2回目からは普通にダブルクリックで開けます。この画面が出るのは最初の1回だけです。',
        figure: 'dialog',
        key: true,
      },
      {
        title: '画面いちばん上に 🐵 が出たら完了',
        body: 'アプリの窓は開きません。メニューバーに住むタイプのアプリです。クリックすると設定が開きます。',
        figure: 'menubar',
      },
    ],
    afterHeading: '最初にやること',
    afterBody: [
      '設定を開くと、同じネットワークにあるスピーカーが自動で並びます。',
      '下げたいものにチェックを入れるだけで準備は終わりです。IPアドレスの入力などは要りません。',
    ],
    afterFine: 'Sonos 以外は、うっかりテレビを下げてしまわないよう初期状態ではオフです。使いたいものだけチェックを入れてください。',
    troubleHeading: 'それでも開けないときは',
    troubleBody: [
      'システム設定 → プライバシーとセキュリティ を開いてください。下のほうに「Kikazaru は開発元を確認できないため、使用がブロックされました」という行と',
      '「このまま開く」',
      'ボタンが出ています。そこからも開けます。',
    ],
    troubleLink: 'こちらから状況を教えてください',
    troubleTail: ['どうしても駄目なら', '。お使いの Mac と macOS のバージョンを添えていただけると助かります。'],
  },
  support: {
    label: 'これから',
    heading: '不具合の報告と、支援について',
    bugTitle: 'うまく動かない・こうしてほしい',
    bugBody:
      '対応してほしいスピーカーや、動かなかった環境を教えてください。Bose SoundTouch はまだ実機で試せていないので、お持ちの方の報告が特に助かります。',
    bugBtn: '要望・バグ報告を送る',
    kofiTitle: '役に立ったら',
    kofiBody:
      'Kikazaru はこれからも無料のままにします。もし毎日の作業が少し楽になったら、300円から。何に使うのかも書いてあります。',
    kofiBtn: 'コーヒーをおごる →',
    kofiFallback: 'うまく表示されないときは Ko-fi のページで',
  },
  foot: {
    made: 'Sonos と Google Home を使っていて自分が困ったので作りました。かなりニッチなのは分かっています。',
    install: 'インストール方法',
    support: '要望・バグ報告',
    copy: 'Kikazaru · macOS 14 以降 · 無料',
  },
  page: {
    title: 'Kikazaru を支える — Kikazaru',
    description: 'Kikazaru はこれからも無料です。もし役に立ったら、コーヒー1杯ぶんだけ。',
    back: 'Kikazaru にもどる',
    heading: '払いたい人だけ、ここから',
    lead: 'Kikazaru は無料です。これからも無料のままにします。このページは払いたい人のために置いてあるだけなので、読み飛ばしてもらって構いません。',
    moneyHeading: 'もらったお金は何に消えるか',
    moneyBody: 'いま出ていくお金はこれくらいです。',
    moneyList: [
      {
        icon: 'badge',
        title: 'Apple の開発者登録',
        note: 'ここが埋まると、インストール時の警告が消えて右クリックの儀式が要らなくなります',
        cost: '年 99 ドル',
      },
      {
        icon: 'speaker',
        title: '対応するスピーカーの実機購入費',
        note: 'Bose SoundTouch はコードだけ書いて、実機がないまま止まっています。ほかのメーカーも増やしたいので、そのたびに1台要ります',
        cost: '未購入',
      },
      {
        icon: 'globe',
        title: 'サイトとドメインの維持費',
        note: 'いまは無料枠に収まっています。人が増えたら足が出ます',
        cost: '現状ほぼ 0 円',
      },
    ],
    payHeading: 'コーヒーをおごる',
    payNote: '300円から。金額は好きに書き換えられます。カードか PayPal で、アカウント登録は要りません。',
    otherHeading: 'お金以外で助かること',
    otherBody: 'お金より、こっちのほうが助かります。',
    otherList: [
      { icon: 'speaker', title: 'Sonos と Google Home 以外を使っている', body: 'Bose SoundTouch はコードだけ書いて未確認です。ほかのメーカーも増やしたいので、何を使っているか教えてもらえると助かります' },
      { icon: 'bug', title: '動かなかった環境を教える', body: 'どの Mac・どの macOS・どのスピーカーで駄目だったか。それだけで直せることが多いです' },
      { icon: 'share', title: '同じことで困っている人に渡す', body: 'かなりニッチな道具なので、届く相手は限られています' },
    ],
    closing: '長々とすみません。使ってもらえているだけで十分です。',
  },
}

export const en: Copy = {
  lang: 'en',
  htmlLang: 'en',
  altHref: '/',
  altLabel: '日本語',
  meta: {
    title: 'Kikazaru — a Mac app that turns the room down while your mic is on',
    description:
      'Automatically lowers your Sonos or Google Home while you dictate or take a call, then puts the volume right back. Free, for macOS.',
  },
  nav: { download: 'Download' },
  hero: {
    tagline: 'Turns the room down<br />while your mic is on',
    sub: 'While you dictate or take a call, Kikazaru quietly lowers your Sonos or Google Home. When you stop talking, the volume comes right back.',
    download: 'Download Kikazaru',
    meta: 'macOS 14+ / Free / ~400 KB',
    note: ['There is ', 'one extra step the first time you open it', '. It takes a minute — worth reading first.'],
  },
  shot: {
    heading: 'That is the whole setup',
    body: 'Speakers on your network show up on their own. **Just tick the ones you want turned down** — no IP addresses to type in.',
    fine: 'Everything except Sonos is off by default, so your TV is not touched by accident. You can also choose per app whether to lower or fully mute.',
    alt: 'The Kikazaru settings window, listing the speakers it found with checkboxes',
    image: '/app-settings-en.png',
  },
  problem: {
    label: 'What you actually want',
    heading: 'Keep the music on, and still talk',
    want: 'You want music on the speakers while you work. You also dictate and take calls. Right now those two things do not fit together, so something gets sacrificed every time.',
    before: 'Today',
    after: 'With Kikazaru',
    musicLoud: 'Music stays loud',
    musicDown: 'Drops while you talk',
    talking: 'You talk',
    transcript: 'Transcript',
    dirty: 'Pull the action items from the notes',
    dirtyMark: 'walking with you that day',
    clean: 'Pull the action items from the notes',
    beforeList: ['Pause the music every time', 'Swap over to headphones', 'The call hears your music too'],
    afterList: ['Leave the music playing', 'No headphones needed', 'Volume returns when you finish'],
    causeHeading: 'Why it does not stop on its own',
    causeLead: ['Dictation apps do lower the volume — but only for ', 'speakers connected to your Mac', '.'],
    okMark: 'Lowered automatically',
    ngMark: 'Not lowered',
    okName: 'Speakers plugged into the Mac',
    okNote: 'Bluetooth, USB, AirPlay',
    ngName: 'Sonos / Google Home',
    ngNote: 'The speaker plays the audio itself',
    causeTail: [
      'Sonos and Google Home play the music themselves, not through your Mac. Your Mac never touches that audio, so it simply cannot turn it down. ',
      'Kikazaru fills exactly that gap.',
    ],
  },
  steps: {
    label: 'How it behaves',
    heading: 'Install it and forget it',
    items: [
      { emoji: '🎙', title: 'You start talking', body: 'It notices the microphone turned on' },
      { emoji: '🙉', title: 'The music drops', body: 'Volume falls in about 0.1 seconds' },
      { emoji: '🐵', title: 'You stop talking', body: 'The original volume comes right back' },
    ],
    tail: 'The menu bar shows 🐵 or 🙉, so you can see at a glance whether the room is currently turned down. Nothing runs while it waits, so it barely touches your battery.',
  },
  speakers: {
    label: 'Supported speakers',
    heading: 'It finds speakers on your network by itself',
    rows: [
      { name: 'Sonos', note: 'Recommended — verified on real hardware', state: 'ok' },
      { name: 'Google Home / Chromecast', note: 'Verified on real hardware', state: 'ok' },
      { name: 'Bose SoundTouch', note: 'Not tested — no hardware to try it on', state: 'wip' },
      { name: 'Anything played by the Mac', note: 'Can be enabled in Settings', state: 'sub' },
    ],
    tail: 'No IP addresses to enter. Everything except Sonos starts switched off so your TV is not turned down by accident. Tick the ones you want.',
  },
  why: {
    label: 'Why this exists',
    heading: 'More and more of the work is spoken',
    body: [
      'Prompting an AI, writing up notes — talking is often faster than typing now. Once dictation becomes an all-day habit, the speaker bleeding into your microphone stops being a curiosity and becomes a small tax you pay every single time.',
      'Pausing the music or reaching for headphones on every take got old, so I built this.',
      'With Kikazaru running, the music can just stay on.',
    ],
  },
  install: {
    label: 'Install',
    heading: 'Five steps to get going',
    intro: 'About a minute in total. Step three is the unusual one — read that carefully.',
    calloutMain: [
      'Kikazaru is not registered with Apple as a developer, so double-clicking it gives you ',
      '"cannot be opened because the developer cannot be verified"',
      '. Nothing is broken.',
    ],
    calloutSub: 'It is a personal app given away for free, which is why it arrives this way. Sorry for the extra step.',
    steps: [
      { title: 'Double-click the Kikazaru.zip you downloaded', body: 'Kikazaru.app appears next to it.' },
      { title: 'Move Kikazaru.app into your Applications folder', body: 'Not required, but it keeps things findable.' },
      {
        title: 'Right-click the icon and choose Open',
        body: 'This is the one trick. Double-clicking will not work. Two-finger click on a trackpad, or control-click, does the same thing.',
        figure: 'contextMenu',
        key: true,
      },
      {
        title: 'Press Open once more in the confirmation box',
        body: 'That grants permission. From the second launch onwards a normal double-click works. You only see this box once.',
        figure: 'dialog',
        key: true,
      },
      {
        title: 'Look for 🐵 at the top of your screen',
        body: 'No window opens — it lives in the menu bar. Click it to open Settings.',
        figure: 'menubar',
      },
    ],
    afterHeading: 'The first thing to do',
    afterBody: [
      'Open Settings and the speakers on your network appear on their own. ',
      'Tick the ones you want turned down and you are done. No IP addresses to type in.',
    ],
    afterFine: 'Everything except Sonos is off by default so your TV is safe. Enable only what you want.',
    troubleHeading: 'If it still will not open',
    troubleBody: [
      'Open System Settings → Privacy & Security. Near the bottom you will find a line about Kikazaru being blocked, with an ',
      'Open Anyway',
      ' button. That works too.',
    ],
    troubleLink: 'tell me what happened',
    troubleTail: ['If none of that helps, ', ' — mentioning your Mac and macOS version really helps.'],
  },
  support: {
    label: 'From here',
    heading: 'What broke, and what helped',
    bugTitle: 'Something is off, or you want more',
    bugBody:
      'Tell me which speaker you want supported, or where it failed. Bose SoundTouch has never been tried on real hardware, so a report from an owner would help a lot.',
    bugBtn: 'Send feedback',
    kofiTitle: 'If it earned its place',
    kofiBody:
      'Kikazaru stays free. If it makes your day a little smoother, anything from ¥300 helps. The page says where it goes.',
    kofiBtn: 'Buy me a coffee →',
    kofiFallback: 'Not loading? Open the Ko-fi page instead',
  },
  foot: {
    made: 'I use Sonos and Google Home, ran into this every day, and built it for myself. Fully aware of how niche it is.',
    install: 'How to install',
    support: 'Feedback',
    copy: 'Kikazaru · macOS 14+ · Free',
  },
  page: {
    title: 'Support Kikazaru — Kikazaru',
    description: 'Kikazaru is free and stays free. If it earned its place, a coffee is welcome.',
    back: 'Back to Kikazaru',
    heading: 'If it earned its place, buy me a coffee',
    lead: 'Kikazaru is free, and it stays free. This page exists for people who want to chip in — not because anyone has to.',
    moneyHeading: 'Where the money actually goes',
    moneyBody: 'Being honest about it, this is roughly what it costs to keep going.',
    moneyList: [
      {
        icon: 'badge',
        title: "Apple's developer program",
        note: 'Once that is covered, the scary install warning disappears and the right-click ritual goes away',
        cost: '$99 / year',
      },
      {
        icon: 'speaker',
        title: 'Buying speakers to support',
        note: 'Bose SoundTouch is written but stuck without hardware. I want to add other brands too, and each one means buying a unit',
        cost: 'not bought yet',
      },
      {
        icon: 'globe',
        title: 'Hosting and the domain',
        note: 'Still inside the free tier. That changes if enough people show up',
        cost: '~$0 for now',
      },
    ],
    payHeading: 'Buy me a coffee',
    payNote: 'Starts at ¥300 — change it to whatever you like. Card or PayPal, no account needed.',
    otherHeading: 'Things that help more than money',
    otherBody: 'Genuinely, these are worth more.',
    otherList: [
      { icon: 'speaker', title: 'You use something other than Sonos or Google Home', body: 'Bose SoundTouch is written but untested. I want to add more brands, so knowing what you own already helps' },
      { icon: 'bug', title: 'Tell me where it broke', body: 'Which Mac, which macOS, which speaker. That is usually enough to fix it' },
      { icon: 'share', title: 'Pass it to someone with the same problem', body: 'It is a niche tool, so it only reaches people through people' },
    ],
    closing: 'Thanks for reading. People actually using it is already the point.',
  },
}

export const dictionaries: Record<Lang, Copy> = { ja, en }
