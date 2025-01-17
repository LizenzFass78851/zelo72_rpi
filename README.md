![GitHub last commit](https://img.shields.io/github/last-commit/zelo72/rpi)![GitHub commit activity](https://img.shields.io/github/commit-activity/m/zelo72/rpi)![GitHub issues](https://img.shields.io/github/issues/zelo72/rpi)![GitHub closed issues](https://img.shields.io/github/issues-closed/zelo72/rpi)![visitors](https://visitor-badge.glitch.me/badge?page_id=zelo72.rpi&left_color=grey&right_color=blue)

## [Domain blocklists](https://github.com/Zelo72/rpi/tree/master/pihole/blocklists) for PiHole, Blokada, Diversion, PersonalDNSfilter, pfBlockerNG, PersonalBlocklist, DNScrypt Proxy & Co.
***Other formats: [Hosts](https://github.com/Zelo72/hosts) | [AdGuard/AdBlock](https://github.com/Zelo72/adguard)***

### ***DNS blacklists*** (Black-/Blocklists)

**Overview:**
| List | Big | Multi | Light | Fake | Personal | 
|:-----|:---:|:-----:|:-----:|:----:|:--------:|
| [Big](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/big.txt)                                       |   | X | X | X | X |
| [Multi](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/multi.txt)                                   |   |   | X |   | X |
| [Light](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/light.txt)                                   |   |   |   |   | X |
| [Fake](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/fake.txt)                                     |   | + | + |   | + |
| [Personal](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/personal.txt)                             |   |   |   |   |   |
| [Affiliate & Tracking](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/affiliatetracking.txt)        | + | + | + |   | + |
| [Threat Intelligence Feeds](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/threat-intelligence.txt) | + | + | + |   | + |
| [DoH-VPN-Proxy-Bypass](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/doh-vpn-proxy-bypass.txt)     | + | + | + |   | + |

*X= contains the named list in the column header    
+= expands the named list in the column header*
         
#### Totallist ***(recommendation)***

[**Big**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/big.txt) - Zelo's "Big" Blocklist: Blocks ads, tracking, metrics, telemetry, fake, phishing, malware, coins, crypto and other "crap". An all-in-one blocklist that does not block any mandatory "functions" - no strict blocking. Dead hosts (hosts addresses that no longer exist) have been removed from this list. It can be used as a standalone blocklist. The prerequisite is that the ad blocker can handle large lists. With Pihole, for example, this is no problem.

> ***Link:***
> https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/big.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/big.stats)

#### Basiclists (included in Big blocklist)

[**Multi**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/multi.txt) - Zelo's "Multi" blocklist: Blocks ads, tracking, metrics, telemetry, phishing, malware, coins, crypto and other "crap". The "light" version of the big list. A light all-in-one blocklist that does not block any mandatory "functions" - no strict blocking. Dead hosts (hosts addresses that no longer exist) have been removed from this list. It can be used as a standalone blocklist.

> ***Link:***
> https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/multi.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/multi.stats)

[**Light**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/light.txt) - Zelo's "Light" blocklist: Blocks ads, tracking, metrics, telemetry. The "very light" version of the multi list. A lightweight blocklist for ad blockers who have problems with large lists that does not block any mandatory "functions" - no strict blocking. Dead hosts (hosts addresses that no longer exist) have been removed from this list.

> ***Link:***
> https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/light.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/light.stats)

[**Fake**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/fake.txt) - Zelo's "Fake" blocklist: Blocks fake stores, -news, -science, -streaming, rip-offs, cost traps and co. Based on various consumer sites, warnings and other fake lists. As a recommended addition to the multi or light blocklist, the domains from the fake blocklist are included in the big blocklist.

> ***Link:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/fake.txt
> 
> ***Sources:*** *Consumer Sites, Trusted Shops, Watchlist Internet, zelo72* - [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/fake.stats)

#### Personallists (included in Light/Multi/Big blocklist)

[**Personal**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/personal.txt) - Zelo's "Personal" blocklist: Blocks ads, tracking, metrics, telemetry and  other "crap". As an extension for other blocklists. The personal blocklist is already included in my light/multi/big blocklist!

> ***Link:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/personal.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/personal.stats)

#### Extensionlists (if required - as an extension to the big, multi or light blocklist)

[**Affiliate&Tracking**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/affiliatetracking.txt) - Zelo's "Affiliate & Tracking Plus" Blocklist: Blocks additional ads, ad links, tracking, metrics and telemetry. An extension to the light/multi/big blocklist. Note: This blocklist also blocks e.g. links marked as ads in Google search or affiliate links in mail offers. ***(Optional)***

> ***Link:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/affiliatetracking.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/affiliatetracking.stats)

[**ThreatIntelligenceFeeds**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/threat-intelligence.txt)- Zelo's "Threat Intelligence Feeds": Blocks Malware, Crypto, Coins, Spam, Scam and Pishing - domains known to spread malware, launch phishing attacks, host command-and-control servers and more. Increases secutity significantly. ***(Optional)***

*An attempt has been made to avoid false positive domains, but still this list may contain false positive domains. Therefore, an admin should be available to allow falsely blocked domains when you use this list. Please report false positive domains.*

> ***Link:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/threat-intelligence.txt
> 
> ***Sources:*** [Stats](https://github.com/Zelo72/rpi/blob/master/pihole/blocklists/threat-intelligence.stats)

[**DoH-VPN-Proxy-Bypass**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/doh-vpn-proxy-bypass.txt) - Zelo's "DoH/VPN/TOR/Proxy Bypass Blocklist": Prevent methods to bypass your DNS: DNS over HTTPS, VPN, TOR, Proxies. To ensure the bootstrap is your DNS server you must redirect standard DNS outbound (UDP 53) to an internal server and block all DoT (TCP 853) outbound. ***(Optional)***

> ***Link:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/doh-vpn-proxy-bypass.txt
> 
> ***Sources:*** [Stats](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/doh-vpn-proxy-bypass.stats)

---

### ***Other lists*** (third party)
*The following lists are already included in my lists!*

[**Kees1958**](https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/kees1958.txt) - Domains only version of Kees1958's EU US most prevalent ads & trackers AdBlock list.     
Homepage: https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist
> ***Link Domains only version:*** https://raw.githubusercontent.com/Zelo72/rpi/master/pihole/blocklists/kees1958.txt

---

### ***Beta/Experimental***

**I am currently testing an "Everything" experimental version of my blocklists with more discreet whitelisting. Testers are welcome.**    
More information and the links to the different versions of the blocklist can be found in the following issue: [German version](https://github.com/Zelo72/rpi/issues/22) | [English version](https://github.com/Zelo72/rpi/issues/23)

*An attempt has been made to avoid false positive domains, but still this list may contain false positive domains. Therefore, an admin should be available to allow falsely blocked domains when you use this list. Please report false positive domains.*

---

### ***Note***

***The blocklists were created for purely personal, private use. They were designed to avoid false positive domains as much as possible and not to block any needed features. Maximum blocking with full functionality. They were [compiled](https://github.com/Zelo72/rpi/tree/master/pihole/blocklists/build) from [numerous sources](https://github.com/Zelo72/rpi/blob/master/SOURCES.md), my own [blacklists](https://github.com/Zelo72/rpi/tree/master/pihole/blocklists/data) and various [whitelists](https://github.com/Zelo72/rpi/blob/master/SOURCES.md#white--dead-list). To keep the lists as small as possible, [dead domains](https://github.com/Zelo72/rpi/blob/master/SOURCES.md#white--dead-list) are removed regularly.***

**The blocklists are updated daily.**

---

### ***Credits***

**A huge thank you to the following list maintainers of the [sources used](https://github.com/Zelo72/rpi/blob/master/SOURCES.md):**

*ABPindo, abpvn, AdAway, adblock.gardar.net, AdguardTeam, AdroitAdorKhan, AhaDNS, alphasoc.net, AmnestyTech, anudeepND, azorult-tracker.net, badmojr, bigdargon, blokadaorg, bongochong, botvrij.eu, boutetnico, cbuijs, cert-pa.it, chrisjudk, common-lisp.net, curbengh, cyberthreatcoalition.org, d3ward, Dan Pollock (someonewhocares.org), DandelionSprout, davidonzo, DRSDavidSoft, durablenapkin, easylist, EasyList-Lithuania, easylist-thailand, EnergizedProtection, FadeMind, guardicore, hl2guide, hole.cert.pl, hoshsadiq, hostfiles.frogeye.fr, hpthreatresearch, iam-py-test, infinitytec, jdlingyu, jkrejcha, joewein.net, JoseGalRe, kargig, Kees1958, KevinThomas0, kriskintel.com, Laicure, latvian-list, matomo-org, metamask, mitchellkrogza, mkb2091, Natizyskunk, nextdns, notracking, ookangzheng, oneoffdallas, orca.pet, osint.digitalside.it, paulgb, Peter Lowe (pgl.yoyo.org), phishing.army, piperun, PolishFiltersTeam, prodaft, quidsup, raghavdua1995, rescure.me, RPiList, rspamd, scafroglia93, ShadowWhisperer, shreyasminocha, socram8888, Spam404, stamparm, stanev.org, Stephan (sjhgvr - oisd.nl), StevenBlack, stonecrusher, stopforumspam.com, T145, tiuxo, tomasko126, travisboss, uBlockOrigin, Ultimate-Hosts-Blacklist, URLhaus, usom.gov.tr, velesila, WaLLy3K, What-Zit-Tooya, windscribe.com, winhelp2002.mvps.org, yecarrillo, Yhonay, zebpalmer, ZeroDot1, zoso.ro*

---

*For a better internet - keep the internet clean!*

---

Test results of around 6000 website views from [WhoTracks.Me website list](https://whotracks.me/websites.html) with active big and affiliate & tracking block list:

![grafik](https://user-images.githubusercontent.com/62211544/137025515-7a9bc4db-2fd6-4792-bed6-d98452d60f1b.png)

#### **Tools to test your AdBlock:**

- [D3 Ward Ad Blocker Test](https://d3ward.github.io/toolz/adblock.html)
- [Block Ads! Test](https://blockads.fivefilters.org)
- [Cover Your Tracks - Tracker/Fingerprinting Test](https://coveryourtracks.eff.org/)
