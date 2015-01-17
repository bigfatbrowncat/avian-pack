# avian-pack
This project is a blend of Avian (http://oss.readytalk.com/avian/) and Android classpath that is (at the moment) far more compatible with the original proprietary JDK Classpath.
## Building
The building is quite simple: 

<ol>
  <li>First of all you should prepare your environment according to this guide:<br/> http://bigfatbrowncat.github.io/cross-building/<br/>You may use any other configuration, of course, but you would crush into many problems, I bet (especially on Windows).</li>
  <li>In order to build Avian and Android classes we should have JDK 7 installed.<br/>
http://www.oracle.com/technetwork/java/javase/downloads/index.html
Be careful! Don't install JDK 8 instead.</li>
  <li><em>[On Windows or Linux]</em> After the JDK is installed you should set the `JAVA_HOME` variable. For example, on Windows it would be something like
  <pre>export JAVA_HOME=/c/Program\ Files/Java/jdk1.7.0_00</pre>
  You don't have to set this variable on OS X where the path could be found automagically.</li>
  <li>Then you should clone the avian-pack repo: 
  <pre>git clone https://github.com/bigfatbrowncat/avian-pack.git
cd avian-pack</pre>
  This step will take the base repo from the server. It's quite fast (about 5-20 seconds on an average web connection speed)</li>
  <li>Now you should fetch all the submodules.
  <pre>make git-refresh</pre>
  This command will clone many necessary repos (most of them are Android components). This will take a dozen of minutes.</li>
  <li>Now it's ready to be built. Just type
  <pre>make</pre>
  The building process is quite slow. It will build all the components and link them together. After all the operations are complete, the result will appear inside <code>avian/build</code> directory.</li>
</ol>
