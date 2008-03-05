Yo Adrian this is the rfacebo version of rfacebook. What is this thing? It's a modified version of rfacebook 0.9.8 and its
associated plugin so that your app can run on facebook and bebo without deploying multiple instances of your app. 
Right now the code is NOT packaged properly as a GEM as it hasn't seen an official "release" of its own. 

Until there's an official release the install process is to:
1) install the regular rfacebook gem (0.9.8)
2) replace it with the code in the gem directory in this package. 
3) install the plugin from this package into your vendor/plugins directory
4) copy facebook.yml to your app's config dir and setup your keys and secrets accordingly
5) setup bebo and facebook callbacks with the proper subdomains. bebo.yourapp.com, facebook.yourapp.com

Current limitations:
Right now the plugin/gem assumes that you are going to set the callback URL to use a subdomain in order to determine which
network the call came from. e.g. facebook.yourdomain.com, bebo.yourdomain.com. This could easily be modified to check for
the fb-network parameter that bebo passes to identify itself, although facebook does not. It may make sense to change
the implementation to do that instead of requiring a subdomain I just haven't had the time to do so.

You can get more information here:
http://javathehutt.blogspot.com/2008/01/rails-realities-part-27-facebook-and.html

Enjoy!