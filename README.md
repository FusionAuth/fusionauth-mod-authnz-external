## FusionAuth Apache Mod External Authentication ![semver 2.0.0 compliant](http://img.shields.io/badge/semver-2.0.0-brightgreen.svg?style=flat-square)

In order to verify a specific role for a user, you must also install `jq` which provides JSON parsing support for bash.

1. `mkdir -p /usr/local/fusionauth/config`
2. Copy `fusionauth_external.sh` and `fusionauth_mod.properties` into `/usr/local/fusionauth/config`
3. Configure Apache to use external auth, see `example/virtual_host` for configuration reference.
  - `sudo apt-get install libapache2-mod-authnz-external`
  - `sudo a2enmod authnz_external authn_socache socache_shmcb`
  - Add `AuthnCacheSOCache shmcb` near the top of `/etc/apache2/apache2.conf`
  - `sudo service apache2 restart`
4. Update `fusionauth_mod_properties` with your URL if it is not localhost.
5. Verify `fusionauth_external.sh` is owned by the user running Apache and has execute permission.




