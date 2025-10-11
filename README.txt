
Last Edit: 10.10.2025

#
# Upstream DNS
#

https://dns.cloudflare.com/dns-query
9.9.9.9
208.67.222.222
2606:4700:4700::1111
2620:fe::fe
2620:fe::9
2620:0:ccc::2


#
# Fallback DNS
#

8.8.8.8
8.8.4.4
149.112.112.112
208.67.220.220
2606:4700:4700::1001
2001:4860:4860::8844
2001:4860:4860::8888



#
# Regex and Blocklists for Pi-Hole , Adguard Home
#

#
# Regular Expressions (Regex): 
#

^(.+[_.-])?adse?rv(er?|ice)?s?[0-9]*[_.-]
^(.+[_.-])?telemetry[_.-]
^adim(age|g)s?[0-9]*[_.-]
^adtrack(er|ing)?[0-9]*[_.-]
^advert(s|is(ing|ements?))?[0-9]*[_.-]
^aff(iliat(es?|ion))?[_.-]
^analytics?[_.-]
^banners?[_.-]
^beacons?[0-9]*[_.-]
^count(ers?)?[0-9]*[_.-]
^mads\.
^pixels?[-.]
^stat(s|istics)?[0-9]*[_.-]
.*ads.*
.*\.tracking\..*
^(.+[_.-])?(facebook|fb(cdn|sbx)?|tfbnw)\.[^.]+$
^https?://(www\.)?livejasmin\.com/(en|de|fr)/[a-zA-Z0-9_-]+$
^https?://(www\.)?xhamsterlive\.com/(en|de|fr)/[a-zA-Z0-9_-]+$

^https?://[^/]+/.*(adserver|ads|advert|advertising|banner|track|tracker|pixel|collect|doubleclick|googlesyndication|
^https?://[^/]+/.*(google-analytics|ga|gtm|googletagmanager|collect|analytics)
^https?://[^/]+/.*(facebook|twitter).(com|net|org)
^https?://[^/]+/.*(criteo|openx|rubicon|pulse|appnexus|adnxs|advertising|adsystem)
^https?://[^/]+/.*(doubleclick|googlevideo|videoad|adservice|adsbygoogle)



#
# Blocklists
#

Easylist
https://easylist.to/easylist/easylist.txt

Easyprivacy
https://raw.githubusercontent.com/ZingyAwesome/easylists-for-pihole/refs/heads/master/easyprivacy.txt


Fanboy's Annoyance List
https://easylist.to/easylist/fanboy-annoyance.txt

Spam404
https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt

NoCoin
https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt


Phishing
https://phishing.army/download/phishing_army_blocklist.txt


NoProxies
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/proxies


Gambling
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/gambling


Streaming
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Streaming


Domain Squatting
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting1

https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/DomainSquatting2


Ransomware
https://raw.githubusercontent.com/blocklistproject/Lists/master/ransomware.txt


Fake Science
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Fake-Science



Facebook
https://raw.githubusercontent.com/crpietschmann/pi-hole-blocklist/main/social-media/blocklist-social-facebook.txt

Tiktok
https://raw.githubusercontent.com/crpietschmann/pi-hole-blocklist/main/social-media/blocklist-social-tiktok.txt

Jugendschutz
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/child-protection



Wildcard Blocklist (Amazon Prime Video will dont work)
https://raw.githubusercontent.com/ph00lt0/blocklist/refs/heads/master/wildcard-blocklist.txt

Prigent-Ads
https://v.firebog.net/hosts/Prigent-Ads.txt

Blocklist - Adservers
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt

Blocklist - Simple Tracking
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt


HaGeZis Ultimate Blocklist
https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt

HaGeZis Anti-Privacy
https://adguardteam.github.io/HostlistsRegistry/assets/filter_46.txt

Roku Blocklist
https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/domains/native.roku.txt













