// End-to-end test of the CodeArena C++ engine under QuickJS (fast path).
import * as std from 'qjs:std';

globalThis.self = globalThis;
globalThis.global = globalThis;
globalThis.window = globalThis;

const jscppSrc = std.loadFile('./assets/vendor/JSCPP.es5.min.js');
const runnerSrc = std.loadFile('./assets/vendor/runner.js');
(0, eval)(jscppSrc + '\n' + runnerSrc);

let pass = 0, fail = 0;
function check(name, code, input, expectOk, expectOut, expectErr) {
  let r;
  const t0 = Date.now();
  try { r = JSON.parse(codeArenaRun(code, input, 0)); }
  catch (e) { print('THROW ' + name + ': ' + e); fail++; return; }
  const ms = Date.now() - t0;
  const okFlag = expectOk === undefined || r.ok === expectOk;
  const outOk = expectOut === undefined || (r.output || '').trim() === expectOut.trim();
  const errOk = expectErr === undefined || r.error === expectErr;
  if (okFlag && outOk && errOk) { pass++; print('PASS ' + name + ' (' + ms + 'ms)'); }
  else {
    fail++;
    print('FAIL ' + name + ' -> ' + JSON.stringify(r).slice(0, 280) + ' (' + ms + 'ms)');
  }
}

const P = '#include <iostream>\nusing namespace std;\n';
const PS = '#include <iostream>\n#include <cstring>\nusing namespace std;\n';

check('hello', P + 'int main(){cout<<"Hola"<<endl;return 0;}', '', true, 'Hola');
check('echo cin', P + 'int main(){int x;cin>>x;cout<<x<<endl;return 0;}', '42', true, '42');
check('a+b', P + 'int main(){int a,b;cin>>a>>b;cout<<a+b<<endl;return 0;}', '3 4', true, '7');
check('loop sum', P + 'int main(){int n;cin>>n;int s=0;for(int i=1;i<=n;i++)s+=i;cout<<s<<endl;return 0;}', '100', true, '5050');
check('if/else', P + 'int main(){int n;cin>>n;if(n%2==0)cout<<"PAR";else cout<<"IMPAR";return 0;}', '7', true, 'IMPAR');
check('arrays', P + 'int main(){int n;cin>>n;int a[100];for(int i=0;i<n;i++)cin>>a[i];for(int i=n-1;i>=0;i--)cout<<a[i]<<" ";return 0;}', '4\n1 2 3 4', true, '4 3 2 1');
check('char string strlen', PS + 'int main(){char s[105];cin>>s;cout<<strlen(s)<<endl;return 0;}', 'espada', true, '6');
// JSCPP strcmp is broken (returns runtime error) — documented limitation.
check('strcmp arrays [known-broken]', PS + 'int main(){char s[105]="abc";char t[105]="abc";cout<<(strcmp(s,t)==0)<<endl;return 0;}', '', false, undefined, 'RUNTIME');
check('char compare', PS + 'int main(){char s[105]="ana";cout<<(s[0]==s[2]);return 0;}', '', true, '1');
check('palindrome loop', PS + 'int main(){char s[105];cin>>s;int n=strlen(s);bool ok=true;for(int i=0;i<n/2;i++)if(s[i]!=s[n-1-i])ok=false;cout<<(ok?"SI":"NO")<<endl;return 0;}', 'reconocer', true, 'SI');
check('recursion fact10', P + 'long long f(int n){if(n==0)return 1;return n*f(n-1);}int main(){cout<<f(10)<<endl;return 0;}', '', true, '3628800');
check('recursion fib15', P + 'int fib(int n){if(n<=1)return n;return fib(n-1)+fib(n-2);}int main(){cout<<fib(15)<<endl;return 0;}', '', true, '610');
check('DFS 3x3 globals', P + 'int vis[10][10];int cnt=0;void go(int i,int j){if(i<0||i>=3||j<0||j>=3||vis[i][j])return;vis[i][j]=1;cnt++;go(i+1,j);go(i-1,j);go(i,j+1);go(i,j-1);}int main(){go(0,0);cout<<cnt<<endl;return 0;}', '', true, '9');
check('long long 20!', P + 'int main(){long long f=1;for(int i=1;i<=20;i++)f*=i;cout<<f<<endl;return 0;}', '', true, '2432902008176640000');
check('2D array', P + 'int p[5][105];int main(){p[2][0]=9;cout<<p[2][0]<<endl;return 0;}', '', true, '9');
check('char op literal', P + 'int main(){int a,b;char op;cin>>a>>op>>b;if(op==\'+\')cout<<a+b;else cout<<a-b;return 0;}', '5 + 3', true, '8');
check('bool not', P + 'int main(){int n=3;bool ok=true;for(int i=0;i<n;i++)ok=!ok;cout<<ok;return 0;}', '', true, '0');
check('while digits', P + 'int main(){int n;cin>>n;int s=0;while(n>0){s+=n%10;n/=10;}cout<<s<<endl;return 0;}', '1234', true, '10');
check('parse error', P + 'int main(){cout<<<<"oops";return 0;}', '', false, undefined, 'PARSE');
check('output limit', P + 'int main(){for(int i=0;i<400000;i++)cout<<"x";return 0;}', '', false, undefined, 'OUTPUT_LIMIT');
check('missing input', P + 'int main(){int x;cin>>x;cout<<x<<endl;return 0;}', '', true, '0');
check('ternary', P + 'int main(){int a=5,b=9;cout<<(a<b?a:b);return 0;}', '', true, '5');
check('break continue', P + 'int main(){int i=0,s=0;while(true){i++;if(i>10)break;if(i%2)continue;s+=i;}cout<<s;return 0;}', '', true, '30');
check('prefix sums', P + 'int main(){int n=5;int a[]={1,2,3,4,5};int pref[10];pref[0]=0;for(int i=0;i<n;i++)pref[i+1]=pref[i]+a[i];cout<<pref[5]-pref[1];return 0;}', '', true, '14');
check('nested loops', P + 'int main(){int n=5;for(int i=1;i<=n;i++){for(int j=0;j<i;j++)cout<<"*";cout<<endl;}return 0;}', '', true, '*\n**\n***\n****\n*****');
check('bubble sort', P + 'int main(){int a[]={4,2,5,1,3};int n=5;for(int i=0;i<n;i++)for(int j=0;j+1<n-i;j++)if(a[j]>a[j+1]){int t=a[j];a[j]=a[j+1];a[j+1]=t;}for(int i=0;i<n;i++)cout<<a[i]<<" ";return 0;}', '', true, '1 2 3 4 5');
check('binary search', P + 'int main(){int a[]={1,3,5,7,9,11};int x=7;int lo=0,hi=5,pos=-1;while(lo<=hi){int mid=(lo+hi)/2;if(a[mid]==x){pos=mid;break;}else if(a[mid]<x)lo=mid+1;else hi=mid-1;}cout<<pos;return 0;}', '', true, '3');
check('struct', P + 'struct P{int x,y;};int main(){P p;p.x=3;p.y=4;cout<<p.x+p.y;return 0;}', '', true, '7');
check('inc dec', P + 'int main(){int i=5;i++;i--;i+=3;cout<<i;return 0;}', '', true, '8');
check('endl chain', P + 'int main(){cout<<1<<" "<<2<<endl<<3<<endl;return 0;}', '', true, '1 2\n3');
check('kadane', P + 'int main(){int a[]={-2,-3,4,-1,-2,1,5,-3};int best=a[0],cur=0;for(int i=0;i<8;i++){cur+=a[i];if(cur>best)best=cur;if(cur<0)cur=0;}cout<<best;return 0;}', '', true, '7');
check('big loop 10k', P + 'int main(){long long s=0;for(int i=0;i<10000;i++)s+=i%7;cout<<s;return 0;}', '', true, '29994');
check('mod negative', P + 'int main(){cout<<(-8%3)<<endl;return 0;}', '', true, '-2');

print('---');
print(pass + ' passed, ' + fail + ' failed');
std.exit(fail > 0 ? 1 : 0);
