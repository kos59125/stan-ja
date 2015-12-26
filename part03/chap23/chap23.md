## 23. Stanプログラムの実行 Execution of a Stan Program
この章ではコンパイルされたStanモデルがサンプリングを使ってどのように実行されるかの概観を提供します。最適化は読み込みと初期化のステップと同じデータを使用しますが，その後サンプリングではなく最適化を行います。
変数の宣言，表現，命令，ブロックについての詳細はこのパートの残りの章で詳しく説明します。

This chapter provides a sketch of how a compiled Stan model is executed using sampling. Optimization shares the same data reading and initialization steps, but then does optimization rather than sampling.
This sketch is elaborated in the following chapters of this part, which cover variable declarations, expressions, statements, and blocks in more detail.

### 23.1. データの読み込みと変換 Reading and Transforming Data
データの読み込みと変換のステップはサンプリング，最適化，診断で共通しています。

The reading and transforming data steps are the same for sampling, optimization and diagnostics.

データの読み込み

Read Data

実行の最初のステップはデータのメモリへの読み込みです。データはファイルから(CmdStan)でもメモリ経由経由(RStanやPyStan)で読み込まれます。詳しくはそれぞれのマニュアルをご覧ください[^注1]。データブロックで定義されたすべての変数が読み込まれます。もし読み込むことができない変数があった場合は，どのデータ変数が足りないかを示すメッセージを出してプログラムは停止します。

The first step of execution is to read data into memory. Data may be read in through file (in CmdStan) or through memory (RStan and PyStan); see their respective manuals for details. 1  All of the variables declared in the data block will be read. If a variable cannot be read, the program will halt with a message indicating which data variable is missing.

それぞれの変数が読み込まれた後，もし制限が宣言されていた場合はその制限が確認されます。例えば，もし変数`N`が`int<lower=0>`と宣言されていた場合，`N`が読み込まれた後，その値が0またはそれ以上であることが確認されます。もし宣言された制約に反する変数があった場合，どの変数が不正なデータを含んでいるか，読み込まれた不正なデータ，宣言された制約を示す警告メッセージを出してプログラムは停止します。

After each variable is read, if it has a declared constraint, the constraint is validated. For example, if a variable N is declared as int<lower=0>, after N is read, it will be tested to make sure it is greater than or equal to zero. If a variable violates its declared constraint, the program will halt with a warning message indicating which variable contains an illegal value, the value that was read, and the constraint that was declared.

データ変換の定義

Define Transformed Data

モデルが読み込まれると，**`the transformed data variable  変換データ変数 でOK?`** 命令が実行され，変換データ変数が定義されます。命令の実行にあたっては，変数への宣言された制約は強制されません。

After data is read into the model, the transformed data variable statements are executed in order to define the transformed data variables. As the statements execute, declared constraints on variables are not enforced.

変換データ変数は`real`型の場合は`NaN`が，`integer`型の場合は最小の整数(絶対値最大で負の値)がセットされ初期化されます。

Transformed data variables are initialized with real values set to NaN and integer values set to the smallest integer (large absolute value negative number).

命令が実行された後，変換データ変数のすべての宣言された制約が確認されます。もし確認が失敗した場合，該当する変数名，値，制約が表示され実行が停止します。

After the statements are executed, all declared constraints on transformed data variables are validated. If the validation fails, execution halts and the variable’s name, value and constraints are displayed.

[^注1] Stanの基礎となっているC++のコードは柔軟でデータをメモリからでもファイルからでも読み込めます。例えば，Rからの呼び出しではデータをファイルからまたは直接Rのメモリから読み込むよう構成することができます。

1 The C++ code underlying Stan is flexible enough to allow data to be read from memory or file. Calls from R, for instance, can be configured to read data from file or directly from R’s memory.
 
### 23.2. Initialization

初期化はサンプリング，最適化，そして診断において同様です。

Initialization is the same for sampling, optimization, and diagnosis

ユーザによる初期値

User-Supplied Initial Values

もしパラメータにユーザによる初期値が設定されている場合，読み込みはデータの読み込みと同じメカニズム，同じファイルフォーマットでなされます。パラメータの宣言された制限は初期値について確認されます。もし宣言された制約に反する変数の値だった場合，プログラムは停止し，診断メッセージが出力されます。

If there are user-supplied initial values for parameters, these are read using the same input mechanism and same file format as data reads. Any constraints declared on the parameters are validated for the initial values. If a variable’s value violates its declared constraint, the program halts and a diagnostic message is printed.

読み込みの後，初期値は制約のない値に変換され，サンプラーの初期化に使われます。

After being read, initial values are transformed to unconstrained values that will be used to initialize the sampler.

境界の値は問題になりやすい

Boundary Values are Problematic

Stanが制約ありから制約なしの空間に変換をおこなうことから，制約の境界上でパラメータの初期化をするのは問題になりやすいです。例えば，以下のような制約があったとき
```
parameters {
  real<lower=0,upper=1> theta;
  // ...
}
```
初期値0は制約なしの値-∞に，初期値1は制約なしの値+∞になってしまいます。浮動小数点計算により逆変換は正しく行われ， **`Jacobian ヤコビアン？`** は発散し**`log probability function 確率密度関数？`** は失敗し例外を発生します。

Because of the way Stan defines its transforms from the constrained to the unconstrained space, initializing parameters on the boundaries of their constraints is usually problematic. For instance, with a constraint
    parameters {
      real<lower=0,upper=1> theta;
      // ...
}
an initial value of 0 for theta leads to an unconstrained value of −∞, whereas a value of 1 leads to an unconstrained value of +∞. While this will be inverse transformed back correctly given the behavior of floating point arithmetic, the Jacobian will be infinite and the log probability function will fail and raise an exception.

ランダムな初期値

Random Initial Values

もしユーザーによる初期値がない場合，デフォルトでは-2から2の間から一様に直接取り出された無制約のパラメータで初期化されます。この初期値の境界は変更可能ですが，0を中心に対象である必要があります。0は初期値の中央値として特別なものです。制約なしの値0は宣言された制約に従う別のパラメータ値と対応します。

If there are no user-supplied initial values, the default initialization strategy is to initialize the unconstrained parameters directly with values drawn uniformly from the interval (−2, 2). The bounds of this initialization can be changed but it is always symmetric around 0. The value of 0 is special in that it represents the median of the initialization. An unconstrained value of 0 corresponds to different parameter values depending on the constraints declared on the parameters.

制約なしの`real`型は何の変換も含みません。そのため制約なしの初期値0は制約ありの値0でもあります。

An unconstrained real does not involve any transform, so an initial value of 0 for the unconstrained parameters is also a value of 0 for the constrained parameters.

0より大きな(0で下方に有界な)パラメータについて，制約なし尺度の初期値0は制約あり尺度の`exp(0) = 1`と一致します。-2は`epx(-2) = .13`と，2は`exp(2) = 7.4`と一致します。

For parameters that are bounded below at 0, the initial value of 0 on the unconstrained scale corresponds to exp(0) = 1 on the constrained scale. A value of -2 corresponds to exp(−2) = .13 and a value of 2 corresponds to exp(2) = 7.4.

上限と下限があるパラメータの場合，制約のない初期値0は上限と下限の中間と対応します。下限0上限1の確率パラメータでは逆ロジットで変換し，制約なしの初期値0は0.5に，-2は0.12に，2は0.88に対応します。0と1以外は縮小され変換されます。

For parameters bounded above and below, the initial value of 0 on the unconstrained scale corresponds to a value at the midpoint of the constraint interval. For probability parameters, bounded below by 0 and above by 1, the transform is the inverse logit, so that an initial unconstrained value of 0 corresponds to a constrained value of 0.5, -2 corresponds to 0.12 and 2 to 0.88. Bounds other than 0 and 1 are just scaled and translated.

制約なしの初期値0をもつ**`Simplexes 単体？`** は制約ありの **`symmetric values`** 対称値と対応します(たとえば，K-simplexでは各値が1/K)。

Simplexes with initial values of 0 on the unconstrained basis correspond to symmetric values on the constrained values (i.e., each value is 1/K in a K-simplex).

正定値行列のコレスキーファクターは対角成分1，のこりが0で初期化されます。なぜなら対角成分はlog変換され，対角成分以下の値は制約がないからです。

Cholesky factors for positive-definite matrices are initialized to 1 on the diagonal and 0 elsewhere; this is because the diagonal is log transformed and the below- diagonal values are unconstrained.

それ以外のパラメータの初期値は示された変換により判断されます。変換については56章で詳細に記述しています。

The initial values for other parameters can be determined from the transform that is applied. The transforms are all described in full detail in Chapter 56.

ゼロ初期値

Zero Initial Values

制約なしの場合，初期値はすべて0にセットされることがあります。これは診断に便利ですし，サンプリングの開始点としても良いです。いったんモデルが走ると，複数の連鎖がより拡散した開始点を持っていることは収束診断の問題の助けになります。収束モニタリングについては55.3を参照してください。

The initial values may all be set to 0 on the unconstrained scale. This can be helpful for diagnosis, and may also be a good starting point for sampling. Once a model is running, multiple chains with more diffuse starting points can help diagnose problems with convergence; see Section 55.3 for more information on convergence monitoring.

### 23.3. Sampling
Sampling is based on simulating the Hamiltonian of a particle with a starting posi- tion equal to the current parameter values and an initial momentum (kinetic energy) generated randomly. The potential energy at work on the particle is taken to be the negative log (unnormalized) total probability function defined by the model. In the usual approach to implementing HMC, the Hamiltonian dynamics of the particle is simulated using the leapfrog integrator, which discretizes the smooth path of the particle into a number of small time steps called leapfrog steps.
Leapfrog Steps
For each leapfrog step, the negative log probability function and its gradient need to be evaluated at the position corresponding to the current parameter values (a more detailed sketch is provided in the next section). These are used to update the momen- tum based on the gradient and the position based on the momentum.
For simple models, only a few leapfrog steps with large step sizes are needed. For models with complex posterior geometries, many small leapfrog steps may be needed to accurately model the path of the parameters.

If the user specifies the number of leapfrog steps (i.e., chooses to use standard HMC), that number of leapfrog steps are simulated. If the user has not specified the number of leapfrog steps, the No-U-Turn sampler (NUTS) will determine the number of leapfrog steps adaptively (Hoffman and Gelman, 2011, 2014).
Log Probability and Gradient Calculation
During each leapfrog step, the log probability function and its gradient must be calculated. This is where most of the time in the Stan algorithm is spent. This log probability function, which is used by the sampling algorithm, is defined over the unconstrained parameters.
The first step of the calculation requires the inverse transform of the uncon- strained parameter values back to the constrained parameters in terms of which the model is defined. There is no error checking required because the inverse transform is a total function on every point in whose range satisfies the constraints.
Because the probability statements in the model are defined in terms of con- strained parameters, the log Jacobian of the inverse transform must be added to the accumulated log probability.
Next, the transformed parameter statements are executed. After they complete, any constraints declared for the transformed parameters are checked. If the constraints are violated, the model will halt with a diagnostic error message.
The final step in the log probability function calculation is to execute the statements defined in the model block.
As the log probability function executes, it accumulates an in-memory represen- tation of the expression tree used to calculate the log probability. This includes all of the transformed parameter operations and all of the Jacobian adjustments. This tree is then used to evaluate the gradients by propagating partial derivatives backward along the expression graph. The gradient calculations account for the majority of the cycles consumed by a Stan program.
Metropolis Accept/Reject
A standard Metropolis accept/reject step is required to retain detailed balance and ensure samples are marginally distributed according to the probability function de- fined by the model. This Metropolis adjustment is based on comparing log probabilities, here defined by the Hamiltonian, which is the sum of the potential (negative log probability) and kinetic (squared momentum) energies. In theory, the Hamilto- nian is invariant over the path of the particle and rejection should never occur. In practice, the probability of rejection is determined by the accuracy of the leapfrog approximation to the true trajectory of the parameters.

If step sizes are small, very few updates will be rejected, but many steps will be required to move the same distance. If step sizes are large, more updates will be rejected, but fewer steps will be required to move the same distance. Thus a balance between effort and rejection rate is required. If the user has not specified a step size, Stan will tune the step size during warmup sampling to achieve a desired rejection rate (thus balancing rejection versus number of steps).
If the proposal is accepted, the parameters are updated to their new values. Otherwise, the sample is the current set of parameter values.

### 23.4. Optimization
Optimization runs very much like sampling in that it starts by reading the data and then initializing parameters. Unlike sampling, it produces a deterministic output which requires no further analysis other than to verify that the optimizer itself con- verged to a posterior mode. The output for optimization is also similar to that for sampling.

### 23.5. Variational Inference
Variational inference also runs similar to sampling. It begins by reading the data and initializing the algorithm. The initial variational approximation is a random draw from the standard normal distribution in the unconstrained (real-coordinate) space. Again, similar to sampling, it outputs samples from the approximate posterior once the algorithm has decided that it has converged. Thus, the tools we use for analyzing the result of Stan’s sampling routines can also be used for variational inference.

### 23.6. Model Diagnostics
Model diagnostics are like sampling and optimization in that they depend on a model’s data being read and its parameters being initialized. The user’s guides for the interfaces (RStan, PyStan, CmdStan) provide more details on the diagnostics available; as of Stan 2.0, that’s just gradients on the unconstrained scale and log probabilities.

### 23.7. Output
For each final sample (not counting samples during warmup or samples that are thinned), there is an output stage of writing the samples.

Generated Quantities
Before generating any output, the statements in the generated quantities block are executed. This can be used for any forward simulation based on parameters of the model. Or it may be used to transform parameters to an appropriate form for output.
After the generated quantities statements execute, the constraints declared on generated quantities variables are validated. If these constraints are violated, the program will terminate with a diagnostic message.

### Write
The final step is to write the actual values. The values of all variables declared as parameters, transformed parameters, or generated quantities are written. Local vari- ables are not written, nor is the data or transformed data. All values are written in their constrained forms, that is the form that is used in the model definitions.
In the executable form of a Stan models, parameters, transformed parameters, and generated quantities are written to a file in comma-separated value (csv) notation with a header defining the names of the parameters (including indices for multivariate parameters).2
 2In the R version of Stan, the values may either be written to a csv file or directly back to R’s memory.
