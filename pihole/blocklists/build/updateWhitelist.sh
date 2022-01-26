#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

cd "$SCRIPTPATH" || exit

# Test internet connection
if ! (ping -c1 -w2 google.de >/dev/null) && ! (ping -c1 -w2 cloudflare.com >/dev/null); then
    echo "No Internet connection! The script will be terminated!"
    exit 1
fi

# Helpfunctions
generateWhitelist() {
    dos2unix -q "$1"
    if [ -s "$1" ]; then
        if [ "$(sed $= -n "$1")" != "0" ]; then
            cat <"$1" | sed -e 's/^[[:space:]]*//' | awk '{print $1}' | grep -Ev '^\s*$|^#|^!' >"$2"
            sortList "$2"
        fi
    fi
    rm -f "$1"
}

sortList() {
    if [ -s "$1" ]; then
        sort -uf "$1" >"$1.sorted"
        mv "$1.sorted" "$1"
    fi
}

convertWhiteToAdBlock() {
    rm -f "$2"
    includesubdomains=$3
    if [ -z "$3" ]; then
        includesubdomains="0"
    fi
    while IFS= read -r domain || [ -n "$domain" ]; do
        if [ "${domain:0:1}" == "#" ] || [ "${domain:0:1}" == "" ]; then
            echo "$domain" | sed 's/^\#/\!/' >>"$2"
            continue
        fi
        if [ "${domain:0:2}" == "*." ]; then
            echo "@@||$(echo "$domain" | sed 's/^\*\.//')^" >>"$2"
        else
            if [ $includesubdomains == "0" ]; then
                echo "@@|$domain^" >>"$2"
            else
                echo "@@||$domain^" >>"$2"
            fi
        fi
    done <"$1"
}

# Start
echo '==========================================='
echo 'Whitelist ...'
echo '==========================================='
echo ""

# Config
regex='(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,}|xn--[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$)'
data=/media/nas/git/rpi/pihole/blocklists/data
work=/media/nas/tmp/work
tmp=$data/tmp

# Referral
curl -s -L https://raw.githubusercontent.com/nextdns/metadata/master/privacy/affiliate-tracking-domains |
    awk '{print $1}' | grep -Ev '^\s*$|^#|^!|^www' | sed -e 's/^/\*\./' >$tmp
generateWhitelist $tmp $tmp.1
cat <$tmp.1 >>$data/white.list.referral
rm -f $tmp.1
sortList $data/white.list.referral
wc -l $data/white.list.referral

cat $data/white.list.referral | grep -Ev '^\s*$|^#|^!|^www|^\*\.' > $data/white.list.reflig
sortList $data/white.list.reflig
wc -l $data/white.list.reflig

# CTech
curl -s -L https://raw.githubusercontent.com/CommsTech/Commsnet/main/Networking/pfSense/Firewall/pfBlockerNG/DNSBL/Whitelists/All_In_One_Whitelist.txt >$tmp
generateWhitelist $tmp $data/white.list.ctech
wc -l $data/white.list.ctech

# KEES
curl -s -L https://raw.githubusercontent.com/Kees1958/W3C_annual_most_used_survey_blocklist/master/RemovedDomains | grep -P "$regex" >$tmp
generateWhitelist $tmp $data/white.list.kees
wc -l $data/white.list.kees

# NT
curl -s -L https://raw.githubusercontent.com/notracking/hosts-blocklists-scripts/master/hostnames.whitelist.txt >$tmp
generateWhitelist $tmp $data/white.list.nt
wc -l $data/white.list.nt

# MKB
curl -s -L https://raw.githubusercontent.com/mkb2091/blockconvert/master/output/whitelist_domains.txt >$tmp
generateWhitelist $tmp $data/white.list.mkb
wc -l $data/white.list.mkb

# EGP
curl -s -L https://raw.githubusercontent.com/EnergizedProtection/unblock/master/basic/formats/domains.txt >$tmp
generateWhitelist $tmp $data/white.list.egp
wc -l $data/white.list.egp

# T145
curl -s -L https://github.com/T145/black-mirror/releases/download/latest/white_domain.txt >$tmp
generateWhitelist $tmp $data/white.list.t145
wc -l $data/white.list.t145

# BMJ
curl -s -L https://raw.githubusercontent.com/badmojr/1Hosts/master/submit_here/exclude_for_all.txt >$tmp
curl -s -L https://raw.githubusercontent.com/badmojr/1Hosts/master/submit_here/exclude_for_mini_Lite_only.txt >>$tmp
generateWhitelist $tmp $data/white.list.bmj
wc -l $data/white.list.bmj

# SW
curl -s -L https://raw.githubusercontent.com/ShadowWhisperer/BlockLists/master/Whitelists/Filter >$tmp
curl -s -L https://raw.githubusercontent.com/ShadowWhisperer/BlockLists/master/Whitelists/Whitelist >>$tmp
generateWhitelist $tmp $data/white.list.sw
wc -l $data/white.list.sw

# SHC
curl -s -L https://someonewhocares.org/hosts/zero/ | grep -P '^#0' | awk '{print $2}' | grep -P "$regex" >$tmp
generateWhitelist $tmp $data/white.list.shc
wc -l $data/white.list.shc

# OISD
cp $data/white.list.oisd $work/oisd.white.old

lynx -dump https://oisd.nl/excludes.php | sed -e 's/^[[:space:]]*//' | grep -P '^\[' | awk -F']' '{print $2}' | grep -P "$regex" >$tmp
generateWhitelist $tmp $data/white.list.oisd

curl -s -L https://dbl.oisd.nl/ | sed -e 's/^[[:space:]]*//' | awk '{print $1}' | grep -Ev '^\s*$|^#' | sort -u >$work/oisd.txt
comm -12 <(tr '[:upper:]' '[:lower:]' <$data/white.list.oisd | sort) <(tr '[:upper:]' '[:lower:]' <$work/oisd.txt | sort) | awk '{print $1}' >$work/oisd.white.equal

comm -13 <(tr '[:upper:]' '[:lower:]' <$work/oisd.white.equal | sort) <(tr '[:upper:]' '[:lower:]' <$data/white.list.oisd | sort) | awk '{print $1}' >$data/white.list.oisd.tmp
mv $data/white.list.oisd.tmp $data/white.list.oisd

#comm -13 <(tr '[:upper:]' '[:lower:]' <$data/black.list.block | sort) <(tr '[:upper:]' '[:lower:]' <$data/white.list.oisd | sort) | awk '{print $1}' >$data/white.list.oisd.tmp
#mv $data/white.list.oisd.tmp $data/white.list.oisd

echo "# $(date +'%Y.%m.%d-%H:%M:%S')" >>$work/oisd.white.added
comm -23 <(tr '[:upper:]' '[:lower:]' <$data/white.list.oisd | sort) <(tr '[:upper:]' '[:lower:]' <$work/oisd.white.old | sort) | awk '{print $1}' >>$work/oisd.white.added
echo "# $(date +'%Y.%m.%d-%H:%M:%S')" >>$work/oisd.white.removed
comm -13 <(tr '[:upper:]' '[:lower:]' <$data/white.list.oisd | sort) <(tr '[:upper:]' '[:lower:]' <$work/oisd.white.old | sort) | awk '{print $1}' >>$work/oisd.white.removed

wc -l $data/white.list.oisd

# AdGuard
curl -s -L https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt |
    grep -P '^\@\@' | sed 's/[\|^\@]//g' | sed 's/$important//' >$tmp

curl -s -L https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt |
    grep -P '^\@\@\|\|' | sed 's/[\|^\@]//g' | sed 's/$important//' | sed -e 's/^/*./' >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exclusions.txt |
    grep -Ev '^\s*$|^#|^!|^\/' | sed 's/[\|^]//g' | sed 's/$important//' >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exclusions.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exceptions.txt |
    grep -P '^\@\@' | sed 's/[\|^\@]//g' | sed 's/$important//' >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/exceptions.txt |
    grep -P '^\@\@\|\|' | sed 's/[\|^\@]//g' | sed 's/$important//' | sed -e 's/^/*./' >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/android.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/banks.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/firefox.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/issues.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/mac.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/sensitive.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

curl -s -L https://raw.githubusercontent.com/AdguardTeam/HttpsExclusions/master/exclusions/windows.txt |
    grep -Ev '^\s*$|^#|^!|^\||^\/' | sed 's/\$/ /' | awk '{print $1}' | grep -P "$regex" >>$tmp

generateWhitelist $tmp $data/white.list.adguard
wc -l $data/white.list.adguard

# hl2guide
curl -s -L https://raw.githubusercontent.com/hl2guide/AdGuard-Home-Whitelist/main/whitelist.txt |
    grep -P '^\@\@' | sed 's/[\|^\@]//g' | sed 's/$important//' >$tmp

generateWhitelist $tmp $data/white.list.hl2guide
wc -l $data/white.list.hl2guide

# Build exclude list
./buildList.sh exclude

# Push personal whitelist to local repositories
cp $data/white.list.important /media/nas/git/hosts/white.list
cp $data/white.list.important /media/nas/git/rpi/pihole/blocklists/white.list

# Convert personal whitelist to AdBlock format
convertWhiteToAdBlock "$data/white.list.important" /media/nas/git/adguard/whitelist.adguard
convertWhiteToAdBlock "$data/white.list.referral" /media/nas/git/adguard/whitelist.referral.adguard 1
sortList /media/nas/git/adguard/whitelist.referral.adguard

# Build host-compiler exclusion lists
# cat <"$data/white.list" | grep -Ev '^\s*$|^#|^!' | sed 's/\*\.//' | sort -u | sed -e 's/^/|/' | sed -e 's/$/^/' >"$data/adblock.exclusions.list"
# cat <"$data/white.list" | grep -Ev '^\s*$|^#|^!' | grep -E '^\*\.' |
#     sed 's/^\*//' | sed 's/^.//' | sed 's/\./\\./g' | sed -e 's/^/\(\\|\|\\.\|\^\)/' |
#     sed -e 's/^/\//' | sed -e 's/$/\(\$\|\\\^\)\//' |
#     sort -u >>"$data/adblock.exclusions.list"

# cat <"$data/white.list.important" | grep -Ev '^\s*$|^#|^!' | sed 's/\*\.//' | sort -u | sed -e 's/^/|/' | sed -e 's/$/^/' >"$data/adblock.exclusions.important"
# cat <"$data/white.list.important" | grep -Ev '^\s*$|^#|^!' | grep -E '^\*\.' |
#     sed 's/^\*//' | sed 's/^.//' | sed 's/\./\\./g' | sed -e 's/^/\(\\|\|\\.\|\^\)/' |
#     sed -e 's/^/\//' | sed -e 's/$/\(\$\|\\\^\)\//' |
#     sort -u >>"$data/adblock.exclusions.important"

# cat <"$data/white.list.referral" | grep -Ev '^\s*$|^#|^!' | sed 's/\*\.//' | sort -u | sed -e 's/^/|/' | sed -e 's/$/^/' >"$data/adblock.exclusions.referral"
# cat <"$data/white.list.referral" | grep -Ev '^\s*$|^#|^!' | grep -E '^\*\.' |
#     sed 's/^\*//' | sed 's/^.//' | sed 's/\./\\./g' | sed -e 's/^/\(\\|\|\\.\|\^\)/' |
#     sed -e 's/^/\//' | sed -e 's/$/\(\$\|\\\^\)\//' |
#     sort -u >>"$data/adblock.exclusions.referral"

echo '==========================================='
echo 'Deadlists ...'
echo '==========================================='

# Build dead list
./buildList.sh dead
./buildList.sh dead.nt

cd "$SCRIPTPATH" || exit
