## 31. ベイズ点推定

観測値$y$が与えられたときのパラメータ$\theta$の事後分布$p(\theta \mid y)$に基づいてベイズ点推定を行なうのに普通に使うやり方は3つあります。すなわち、最頻値（最大値）、平均値、中央値です。

### 31.1. 事後最頻値の推定

この節では、事後分布を最大化するようなパラメータ$\theta$をもととする推定値について述べ、続いて次の節では平均値と中央値について議論します。

モデルの事後最頻値に基づく推定値は次式のように定義できます。

$$ \hat{\theta}=\mathrm{argmax}_{\theta}\,p(\theta\mid y) $$

存在するならば、$\hat{\theta}$は、与えられたデータのもとでのパラメータの事後密度を最大化します。事後最頻値は、最大事後(maximum a posteriori, MAP)推定値とも呼ばれます。

24章と30.1節で議論したように、ただひとつの事後最頻値が存在するとは限りません。事後最頻値を最大にするような値は、ひとつも存在しないこともありえますし、2つ以上のこともありえます。そのような場合、事後最頻値の推定値は定義されません。ほとんどのオプティマイザと同様に、Stanのオプティマイザでもそうした状況では問題が発生します。大域的には最大ではないような、局所最大値を返すこともありえます。

事後最頻値が存在する場合には、その値は、対数事前分布に負号をつけたものに等しいような罰則関数を持つ罰則付き最尤推定値に対応するでしょう。これはベイズの定理から導かれます。

$$ p(\theta\mid y)=\frac{p(y\mid\theta)p(\theta)}{p(y)} $$

これにより次式が保証されます。

$$ \begin{array}{ll}\mathrm{argmax}_{\theta}\ p(\theta\mid y) &= \mathrm{argmax}_{\theta}\ \frac{p(y\mid\theta)p(\theta)}{p(y)}\\ &= \mathrm{argmax}_{\theta}\ p(y\mid\theta)p(\theta)\end{array} $$

密度は正値をとり、対数が厳密に単調であることから次式が保証されます。

$$ \mathrm{argmax}_{\theta}\ p(y\mid\theta)p(\theta) = \mathrm{argmax}_{\theta}\ \log p(y\mid\theta) + \log p(\theta) $$

事前分布（正則でも非正則でも）が一様である場合、事後最頻値は最尤推定値と同じになります。

普通に使われる罰則関数ほとんどについて、確率的に同じものが存在します。例えば、リッジ罰則関数は係数への正規事前分布に対応しますし、Lassoはラプラス事前分布に対応します。この逆も常に真です。対数事前分布に負号をつけたものは常に罰則関数と見なすことができます。

### 31.2. 事後平均値の推定

標準的なベイズ法では点推定には（あると仮定して）事後平均値が使われます。定義は次式です。

$$ \hat{\theta} = \int \theta p(\theta\mid y)d\theta $$

事後平均値はまさにベイズ推定量とよく呼ばれます。推定値の期待二乗誤差を最小にする推定量だからです。

各パラメータの事後平均値の推定値は、Stanのインターフェイスから返されます。インターフェイスとデータフォーマットの詳細はRstan、CmdStan、PyStanのユーザーズガイドを参照してください。

事後最頻値が存在しない場合でも、事後平均値が存在することは少なくありません。例えば、$\mathsf{Beta}(0.1, 0.1)$の場合、事後最頻値はありませんが、事後平均値はきちんと定義されて、値は0.5となります。

事後平均値が存在しないのに、事後最頻値は存在するという状況のひとつは、事後分布がコーシー分布$\mathsf{Cauchy}(\mu,\tau)$の場合です。事後最頻値は$\mu$ですが、事後平均値を表す積分は発散します。そのような幅の広い事後分布(**訳注**: 原文はpriorだがposteriorの誤り)は、実際にモデリングを使うときにはめったに出てきません。パラメータにコーシー分布の事前分布を使うときでも、データより十分な制約が与えられるので、事後分布は行儀が良くなり、平均値も存在するようになります。

事後平均値が存在しても、意味がないものであることもあります。混合分布モデルで起きる多峰の事後分布の場合や、閉区間での一様分布の場合がそれに当たります。

### 31.3. 事後中央値の推定

事後中央値（すなわち50番目の百分位点または0.5分位）は、ベイズモデルの報告によく使われる、もうひとつの点推定値です。事後中央値は、推定値の誤差の期待絶対値を最小化します。こうした推定値は、さまざまなStanのインターフェイスで返されます。フォーマットについてのさらに情報を得るにはRStan、PyStan、CmdStanのユーザーズガイドを参照してください。

事後中央値が意味のないものになることもありえますが、事後平均値が存在しないようなときでも多くの場合、事後中央値は存在します。コーシー分布もこれにあてはまります。
