
Last Edit: 10.10.2025

#
# Upstream DNS
#

1.1.1.1
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

#
# Custom Rules Adguard Home
#

/^(.+[_.-])?adse?rv(er?|ice)?s?[0-9]*/
/^pixels?[-.]*/
^stat(s|istics)?[0-9]*[_.-]
/.*ads./*
.*\.tracking\..*
^https?://(www\.)?livejasmin\.com/(en|de|fr)/[a-zA-Z0-9_-]+$
^https?://[^/]+/.*(adserver|ads|advert|advertising|banner|track|tracker|pixel|collect|doubleclick|googlesyndication|
^https?://[^/]+/.*(google-analytics|ga|gtm|googletagmanager|collect|analytics)
^https?://[^/]+/.*(criteo|openx|rubicon|pulse|appnexus|adnxs|advertising|adsystem)
||ecs.office.com^$important
||office.com^$important
||detectportal.firefox.com^$important
||firefox.settings.services.mozilla.com^$important
||css.hotnakedwomen.com^$important
||facebook.com^$important
||de-de.facebook.com^$important
||static.xx.fbcdn.net^$important
||ic-ut-nss.xhcdn.com^$important
||stripchatgirls.com^$important
||www.gstatic.com^$important
||static-lvlt.xhcdn.com^$important
||content-signature-2.cdn.mozilla.net^$important
||static-nss.xhcdn.com^$important
||ic-nss.flixcdn.com^$important
||cdn.hotnakedwomen.com^$important
||creative.xlivrdr.com^$important
||support.mozilla.org^$important
||cdn81960837.ahacdn.me^$important
||www.wisecleaner.net^$important
||xhamsterlive.com^$important
||encrypted-tbn3.gstatic.com^$important
||fonts.gstatic.com^$important
||ei.phncdn.com.sds.rncdn7.com^$important
||ei.phncdn.com^$important
||p2p-fra1.discovery.steamserver.net^$important
||3cx.com/smb/^$important
||google-analytics^$important
||yt4.ggpht.com^$important
||photos-ugc.l.googleusercontent.com^$important
||a1967.dscr.akamai.net^$important
||atruvia.scene7.com^$important
||cdni.hotnakedwomen.com^$important
||p2p-ams1.discovery.steamserver.net^$important
@@||www.chaturbate.com^$important
@@||de.chaturbate.com^$important

DNS Rebind Protection 
 IPv4
! Private
/^10\.(?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})$/
/^172\.(?:1[6-9]|2\d|3[0-1])\.(?:\d{1,3})\.(?:\d{1,3})$/
/^192\.168\.(?:\d{1,3})\.(?:\d{1,3})$/
! Link-Local
/^169\.254\.(?:\d{1,3})\.(?:\d{1,3})$/
! Loopback
/^127\.(?:\d{1,3})\.(?:\d{1,3})\.(?:\d{1,3})$/
! Unspecified
/^0\.0\.0\.(?:\d{1,3})$/
! IPv6
! Unique Local Address (ULA)
/^f[cd][0-9a-f]{2}:/
! Link-Local
/^fe80:/
! Loopback
/^::1$/
! Unspecified
/^::$/
! Host
/^([a-z0-9\-]+\.)?(localhost|localdomain|ip6-localhost)$/


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

Entropy Domains
https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/domains/dga14.txt
https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/domains/dga30.txt

DNS bypass Blocklist
https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/domains/doh.txt

Roku Blocklist
https://raw.githubusercontent.com/hagezi/dns-blocklists/refs/heads/main/domains/native.roku.txt


Jugendschutz
https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/child-protection

Porn Blocklists
https://raw.githubusercontent.com/RPiList/specials/refs/heads/master/Blocklisten/pornblock1
https://raw.githubusercontent.com/RPiList/specials/refs/heads/master/Blocklisten/pornblock2










