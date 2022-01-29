#!/bin/bash
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

cd "$SCRIPTPATH" || exit

# Test internet connection
if ! (ping -c1 -w2 google.de >/dev/null) && ! (ping -c1 -w2 cloudflare.com >/dev/null); then
    echo "No Internet connection! The script will be terminated!"
    exit 1
fi

# Base
name=$1
basedir=/media/nas/git/rpi/pihole/blocklists/build
builddir=/media/nas/git/rpi/pihole/blocklists/build
sourcedir=$basedir/$name
mkdir -p "$sourcedir"

# Config
getConfigValue() {
    grep -w "$1" "$2" | awk -F'=' '{print $2}'
}

inConfig() {
    if cat <"$config" | grep -Ev '^\s*$|^#|^!' | grep -qw "$1"; then
        return 0
    else
        return 1
    fi
}

config=$sourcedir/$name.config
touch "$config"

# Build config
buildconfig=$builddir/build.config
touch $buildconfig
dos2unix -q $buildconfig

repodomains=$(getConfigValue "repodomains" $buildconfig)
repohosts=$(getConfigValue "repohosts" $buildconfig)
repoadguard=$(getConfigValue "repoadguard" $buildconfig)
repodata=$(getConfigValue "repodata" $buildconfig)

# Domain based configuration files
white=$sourcedir/$name.white
black=$sourcedir/$name.black
block=$sourcedir/$name.block
unblock=$sourcedir/$name.unblock
touch "$white" "$block" "$black" "$unblock"

# List based configuration files
whitelists=$sourcedir/$name.config.whitelists
deadlists=$sourcedir/$name.config.deadlists
excludelists=$sourcedir/$name.config.excludelists
sourcelists=$sourcedir/$name.config.sourcelists
blacklists=$sourcedir/$name.config.blacklists
prioblocklists=$sourcedir/$name.config.prioblocklists
unblocklists=$sourcedir/$name.config.unblocklists
touch "$whitelists" "$deadlists" "$excludelists" "$sourcelists" "$blacklists" "$prioblocklists" "$unblocklists"

# Header configuration
header=$sourcedir/$name.header
touch "$header"

# AdGuard host compiler configuration
json=$sourcedir/$name.json
jsonbase=$basedir/adblock.json

# Input
if inConfig "white" || inConfig "dead"; then
    indir=$(getConfigValue "reposourceswhite" $buildconfig)
else
    indir=$(getConfigValue "reposources" $buildconfig)
fi
mkdir -p "$indir"

# Output
outdir=$sourcedir/out
mkdir -p "$outdir"
domains=$outdir/$name.domains
hosts=$outdir/$name.hosts
adblock=$outdir/$name.adblock
stats=$outdir/$name.stats

# Valid domain regex
regex="(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,}|xn--[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$)"

# Version
version=$(date +'%Y.%m%d.%H%M%S')

# Helpfunctions
getDomainsFromList() {
    type=$5
    if [ -z "$5" ]; then
        type="0"
    fi
    if [ -s "$1" ]; then
        while IFS= read -r list || [ -n "$list" ]; do
            if [ "${list:0:1}" == "#" ] || [ "${list:0:1}" == "" ]; then
                continue
            fi
            extractValidDomains $type "$list" >>"$2"
        done <"$1"
        sortList "$2"

        # Extend FLD from SLD
        if [ "$4" == "1" ]; then
            extendFLDfromSLD "$2"
        fi

        # Extend missing WWW/FLD
        if [ "$3" == "1" ]; then
            extendWWW "$2"
            extendFLD "$2"
        fi
    fi
}

getRegexDomainsFromWilcardList() {
    if [ -s "$1" ]; then
        while IFS= read -r list || [ -n "$list" ]; do
            if [ "${list:0:1}" == "#" ] || [ "${list:0:1}" == "" ]; then
                continue
            fi
            convertWildcardToRegex "$list" >>"$2"
        done <"$1"
        sortList "$2"
        if inConfig "debug"; then
            cp "$2" "$2".regex
        fi
    fi
}

convertWildcardToRegex() {
    dos2unix -q "$1"
    cat <"$1" | sed -e 's/^[[:space:]]*//' | grep -Ev '^\s*$|^#|^!' | awk '{print $1}' | grep -E '^\*\.|^\.' |
        sed 's/^\./\(\.\|\^\)/' | sed 's/^\*\./\(\.\|\^\)/' | sed 's/\./\\./g' | sed 's/\-/\\-/g' | sed 's/\*/\.\*/g' | sed -e 's/$/\$/' >tmp

    cat <"$1" | sed -e 's/^[[:space:]]*//' | grep -Ev '^\s*$|^#|^!' | awk '{print $1}' | grep -Ev '^\*\.|^\.' | grep -E '\*' |
        sed -e 's/^/\^/' | sed 's/\./\\./g' | sed 's/\-/\\-/g' | sed 's/\*/\.\*/g' | sed -e 's/$/\$/' >>tmp

    sort -u tmp
    rm -f tmp
}

extractValidDomains() {
    # Sourcetype $1: 0=Domains / 1=Hosts / 2=Adblock / 3=Whitelist / 4=Deadlist

    dos2unix -q "$2"

    # Domains
    if [ "$1" == "0" ]; then
        cat <"$2" | sed -e 's/^[[:space:]]*//' | awk '{print $1}' | grep -Ev '^\s*$|^#|^!' | sed 's/^\.//' | sed 's/^\*\.//' | grep -P "$regex"
    fi
    # Hosts
    if [ "$1" == "1" ]; then
        cat <"$2" | sed -e 's/^[[:space:]]*//' | grep -Ev '^\s*$|^#|^!|localhost.localdomain' | awk '{print $2}' | sed 's/^\.//' | sed 's/^\*\.//' | grep -P "$regex"
    fi
    # Adblock
    if [ "$1" == "2" ]; then
        cat <"$2" | sed -e 's/^[[:space:]]*//' | grep ^\|\|.* | sed 's/[\|^]//g' |
            sed 's/$popup,third-party//' |
            sed 's/$important,all//' |
            sed 's/$third-party//' |
            sed 's/$popup//' |
            sed 's/$important//' |
            sed 's/$all//' |
            sed 's/$document//' |
            sed 's/$doc//' |
            sed 's/$3p//' |
            sed 's/$1p//' |
            grep -P "$regex"
    fi
    # Whitelist
    if [ "$1" == "3" ]; then
        cat <"$2" | sed -e 's/^[[:space:]]*//' | awk '{print $1}' | grep -Ev '^\s*$|^#|^!' # | sed 's/^\./\*\./' | sed 's/^\*\.\*\./\*\./'
    fi
    # Deadlist
    if [ "$1" == "4" ]; then
        cat <"$2" | sed -e 's/^[[:space:]]*//' | awk '{print $1}' | grep -Ev '^\s*$|^#|^!' | sed 's/^\.//' | sed 's/^\*\.//'
    fi
}

extendWWW() {
    cat <"$1" | grep -Ev '^www\.' | grep -P '(^[a-zA-Z0-9](?:[a-zA-Z0-9\-]*\.{1}[a-zA-Z0-9\-]*$))' | sed -e 's/^/www./' | grep -P "$regex" >"$1.www"
    cat "$1.www" >>"$1"
    rm "$1.www"
    sortList "$1"
}

extendFLD() {
    cat <"$1" | grep -P '(^[wW]{3}\.(?:[a-zA-Z0-9\-]*\.{1}[a-zA-Z0-9\-]*$))' | sed -r 's/^(www\.)//' | grep -P "$regex" >"$1.fld"
    cat "$1.fld" >>"$1"
    rm "$1.fld"
    sortList "$1"
}

extendFLDfromSLD() {
    cat <"$1" | sed -e 's/^[[:space:]]*//' | grep -Ev '^\s*$|^#|^!|^www\.|ip6\.arpa$' | awk '{print $1}' | grep -P '(^[a-zA-Z0-9].*\.(?:[a-zA-Z0-9\-]*\.{1}[a-zA-Z0-9\-]*$))' | grep -P "$regex" >"$1.sld"
    cat <"$1.sld" | grep -Po '([a-zA-Z0-9\-]*\.{1}[a-zA-Z0-9\-]{2,}$)|([a-zA-Z0-9\-]*\.{1}(ac|co|gov|ltd|me|net|nhs|nic|org|plc|sch|aaa|aca|acct|ae|ar|biz|br|cn|club|ebiz|gr|gb|game|fin|eu|hu|id|idv|in|info|jp|jur|law|mex|no|nom|or|pp|pro|qc|se|sa|ru|recht|radio|uk|us|uy|za|web)\.{1}[a-zA-Z]{2,}$)' | grep -P "$regex" >"$1.fld"

    cat <"$1.sld" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.1"
    cat <"$1.fld.1" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.2"
    cat <"$1.fld.2" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.3"
    cat <"$1.fld.3" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.4"
    cat <"$1.fld.4" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.5"
    cat <"$1.fld.5" | sed 's/\./ /' | awk '{print $2}' | grep -P "$regex" >"$1.fld.6"

    cat <"$1.fld" "$1.fld.1" "$1.fld.2" "$1.fld.3" "$1.fld.4" "$1.fld.5" "$1.fld.6" >>"$1"
    rm -f "$1.sld" "$1.fld" "$1.fld.1" "$1.fld.2" "$1.fld.3" "$1.fld.4" "$1.fld.5" "$1.fld.6"
    sortList "$1"
}

sortList() {
    touch "$1"
    if [ -s "$1" ]; then
        sort -uf "$1" >"$1.sorted"
        mv "$1.sorted" "$1"
    fi
}

printIncCount() {
    c=$(wc -l "$domains" | awk '{print $1}')
    echo "$c (+$((c - cdo)))"
    cdo=$c
}

printDecCount() {
    c=$(wc -l "$domains" | awk '{print $1}')
    echo "$c (-$((cdo - c)))"
    cdo=$c
}

removeDomains() {
    if [ -s "$1" ] && [ -s "$2" ]; then
        comm -13 <(tr '[:upper:]' '[:lower:]' <"$1" | sort) <(tr '[:upper:]' '[:lower:]' <"$2" | sort) | awk '{print $1}' >"$2.tmp"
        if inConfig "debug"; then
            echo "# ---- START ----" >>"$1.removed"
            comm -12 <(tr '[:upper:]' '[:lower:]' <"$1" | sort) <(tr '[:upper:]' '[:lower:]' <"$2" | sort) | awk '{print $1}' >>"$1.removed"
            echo "# ---- END ----" >>"$1.removed"
        fi
        mv "$2.tmp" "$2"
        rm "$1"
    fi
}

removeDomainsWildcard() {
    if [ -s "$1" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            if [ "${domain:0:1}" == "#" ] || [ "${domain:0:1}" == "" ]; then
                continue
            fi
            cat <"$2" | rg -N "$domain" >>"$2.wildcard"
        done <"$1"
        rm "$1"
        if [ -s "$2.wildcard" ]; then
            sortList "$2.wildcard"
            removeDomains "$2.wildcard" "$2"
        fi
    fi
}

addDomains() {
    if [ -s "$1" ]; then
        if inConfig "debug"; then
            comm -23 <(tr '[:upper:]' '[:lower:]' <"$1" | sort) <(tr '[:upper:]' '[:lower:]' <"$2" | sort) | awk '{print $1}' >"$1.added"
        fi
        cat <"$1" | sed -e 's/^[[:space:]]*//' | grep -Ev '^\s*$|^#|^!' | awk '{print $1}' | grep -P "$regex" >>"$2"
        sortList "$2"
        rm "$1"
    fi
}

printConfig() {
    if [ -s "$2" ]; then
        c=$(wc -l <(cat <"$2" | grep -Ev '^\s*$|^#') | awk '{print $1}')
        if [ "$c" != "0" ]; then
            echo "$1 - $c:"
            echo ""
            cat <"$2" | grep -Ev '^\s*$|^#' | sed -e 's/^/   /'
            echo ""
        fi
    fi
}

printConfigLocal() {
    if [ -s "$2" ]; then
        c=$(wc -l <(cat <"$2" | grep -Ev '^\s*$|^#') | awk '{print $1}')
        if [ "$c" != "0" ]; then
            echo " $1 - $c:"
            echo ""
            echo "$2" | grep -Po '[a-zA-Z0-9-_\.]*$' | sed -e 's/^/   /'
            echo ""
        fi
    fi
}

printHeader() {
    cat "$header"
    echo "#"
    cat "$header".ext
    echo "#"
    echo "# $1 unique Domains - Version $version"
    echo "#"
}

LinkToFilename() {
    echo "$1" | sed 's/http:\/\///' | sed 's/https:\/\///' | sed 's/www\.//' | sed 's/bitbucket.org\///' |
        sed 's/raw.githubusercontent.com\///' | sed 's/gist.githubusercontent.com\///' |
        sed 's/gitlab.com\///' | sed 's/github.com\///' | sed 's/gitlab\.//' | sed 's/\/raw\master\//_/' |
        sed 's/\/raw\//_/' | sed 's/\/master\//_/' | sed 's/\/main\//_/' | sed 's/.txt//' |
        sed 's/\.php?hostformat=hosts&showintro=0&mimetype=plaintext//' |
        sed 's/\/domain?format=plain//' |
        sed 's/%20//g' | sed 's/%2B//g' | sed "s/[\']//g" |
        sed 's/[\/?=&]/_/g' |
        awk '{print tolower($0)}'
}

convertWhiteToAdblock() {
    rm -f "$2"
    if [ -s "$1" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            if [ "${domain:0:1}" == "#" ] || [ "${domain:0:1}" == "" ]; then
                continue
            fi
            if [ "${domain:0:2}" == "*." ]; then
                echo "@@||$(echo "$domain" | sed 's/^\*\.//')^" >>"$2"
            else
                echo "@@|$domain^" >>"$2"
            fi
        done <"$1"
    fi
    touch "$2"
}

getMd5() {
    if [ -s "$1" ]; then
        md5sum "$1" | awk '{print $1}'
    else
        echo "0"
    fi
}

compareFiles() {
    md51=1
    md52=2
    if [ -s "$1" ]; then
        md51=$(getMd5 "$1")
    fi
    if [ -s "$2" ]; then
        md52=$(getMd5 "$2")
    fi
    if [ "$md51" == "$md52" ]; then
        return 0
    else
        return 1
    fi
}

# Start
echo ""
echo "Start: $(date +'%Y.%m-%d-%H:%M:%S')"

# Cleanup
touch "$outdir"/md5.old
rm -f "$domains" "$stats"
rm -f "$domains".* "$stats".*
rm -f "$outdir"/md5.new

cd "$sourcedir" || exit
echo ""
(
    if [ ! -s "$sourcelists" ]; then
        echo "No configuration files found. Empty configuration files were created."
        echo "$sourcedir"
        exit 1
    fi

    echo "### Compile $name Blocklist ###"
    echo ""

    # Print config
    echo "Config:"
    echo ""
    printConfig "** Build" "$config"
    printConfigLocal "+ Blacklist" "$black"
    printConfig "++ Blacklists" "$blacklists"
    printConfigLocal "+ Prioritized Block" "$block"
    printConfig "++ Prioritized Blocklists" "$prioblocklists"
    printConfig "-- Excludelists" "$excludelists"
    printConfig "-- Deadlists" "$deadlists"
    printConfigLocal "- White" "$white"
    printConfig "-- Whitelists" "$whitelists"
    printConfigLocal "- Unblock" "$unblock"
    printConfig "-- Unblocklists" "$unblocklists"

    # Init
    echo "Initialize ..."

    dos2unix -q "$sourcedir"/*

    echo ""

    # Download and convert Sourcelists
    echo "# Download and convert Sourcelists ..."
    echo ""

    i=0
    (
        printf "%+4s | %+7s | %-7s | %-6s | %-7s | %-9s | %s\n" "Nr" "Count" "Format" "Source" "Status" "File" "URL/File"
        while IFS= read -r url || [ -n "$url" ]; do
            if [ "${url:0:1}" == "#" ] || [ "${url:0:1}" == "" ]; then
                continue
            fi

            ((i++))

            # Determine list type
            if inConfig "white"; then
                listtype=3 # Whitelist
                listtypename="white"
            elif inConfig "dead"; then
                listtype=4 # Deadlist
                listtypename="dead"
            else
                listtype=0 # Domains
                listtypename="domains"

                if [ "${url:0:1}" == "!" ]; then
                    url=$(echo "$url" | awk '{print $2}')
                    listtype=1 # Hosts
                    listtypename="hosts"
                fi
                if [ "${url:0:1}" == "&" ]; then
                    url=$(echo "$url" | awk '{print $2}')
                    listtype=2 # Adblock
                    listtypename="adblock"
                fi
            fi

            echo "$i. $listtypename - $url" >>"$domains".sourceurls

            # Processing according to source and list type
            if [ "${url:0:4}" == "http" ]; then # online
                source="http"
                filename=$(LinkToFilename "$url").txt
                file=$indir/$filename
                curl -s -L "$url" >"$file.tmp"
                extractValidDomains $listtype "$file.tmp" >"$file.domains"
                rm "$file.tmp"
            else # local
                source="local"
                filename=$(echo "$url" | grep -Po '[a-zA-Z0-9-_\.]*$')
                file=$indir/$filename
                extractValidDomains $listtype "$url" >"$file.domains"
                url="$filename"
            fi

            # Check if the source has been changed
            if compareFiles "$file" "$file.domains"; then
                filestatus="unchanged"
            else
                filestatus="changed"
            fi

            # If the downloaded source contains domains, use them,
            # otherwise use a cached local copy of the source.
            c=$(wc -l "$file.domains" | awk '{print $1}')
            if [ ! "$c" ] || [ "$c" == "0" ]; then
                c=0
                filestatus="OFFLINE"
                rm "$file.domains"
                if [ -s "$file" ]; then
                    c=$(wc -l "$file" | awk '{print $1}')
                    url="USE LOCAL COPY: $filename"
                    filestatus="unchanged"
                fi
                status="OFFLINE"
            else
                mv "$file.domains" "$file"
                status="online"
            fi

            # Add domains to the domains list
            if [ -s "$file" ]; then
                cat "$file" >>"$domains"
            fi
            #echo "$file" >>$builddir/sourcefiles.txt

            printf "%+4s | %+7s | %-7s | %-6s | %-7s | %-9s | %s\n" "$i" "$c" "$listtypename" "$source" "$status" "$filestatus" "$url"
        done <"$sourcelists"
    ) | tee "$header.ext"
    sed -i 's/^/# /' "$header.ext"
    echo ""

    # Build Domainlist
    echo "# Build $name Domainlist ..."
    echo ""

    echo "Stats $name:"
    echo ""

    echo -n "** Source (raw):    "
    cdo=$(wc -l "$domains" | awk '{print $1}')
    echo "$cdo"

    echo -n "== Source (unique): "
    sortList "$domains"
    printDecCount

    # Save unique domain list
    if inConfig "unique"; then
        cp "$domains" "$domains".unique
    fi

    # Add Domains from personal Blacklists
    if [ -s "$black" ]; then
        cat <"$black" >>"$domains".blacklist
    fi
    getDomainsFromList "$blacklists" "$domains".blacklist 0 0

    if [ -s "$domains".blacklist ]; then
        echo -n "++ Black:           "
        addDomains "$domains".blacklist "$domains"
        printIncCount
    fi

    # Remove excluded Domains
    getDomainsFromList "$excludelists" "$domains".excludelist 0 0

    if [ -s "$domains".excludelist ]; then
        echo -n "-- Exclude:         "
        removeDomains "$domains".excludelist "$domains"
        printDecCount
    fi

    # Save domain list for later dead domains check
    if inConfig "checkfordead"; then
        cp "$domains" "$domains".checkfordead
    fi

    # Remove whitelisted Domains
    if [ -s "$white" ]; then
        cat <"$white" >>"$domains".whitelist
    fi
    getDomainsFromList "$whitelists" "$domains".whitelist 1 1 3

    if [ -s "$domains".whitelist ]; then
        echo -n "-- White:           "
        removeDomains "$domains".whitelist "$domains"

        # Build Adblock whitelist
        if inConfig "adblockwhite"; then
            if [ -s "$white" ]; then
                convertWhiteToAdblock "$white" "$sourcedir"/exceptions.txt
            fi
        fi

        printDecCount
    fi

    # Remove wildcard whitelisted Domains
    if [ -s "$white" ]; then
        cat <"$white" | grep -E '\*' >"$domains".whitelist.wildcards.tmp
        convertWildcardToRegex "$domains".whitelist.wildcards.tmp >>"$domains".whitelist.wildcards
        rm -f "$domains".whitelist.wildcards.tmp
    fi
    getRegexDomainsFromWilcardList "$whitelists" "$domains".whitelist.wildcards

    if [ -s "$domains".whitelist.wildcards ]; then
        echo -n "-- White(*):        "
        removeDomainsWildcard "$domains".whitelist.wildcards "$domains"
        printDecCount
    fi

    # Remove dead Domains
    getDomainsFromList "$deadlists" "$domains".deadlist 0 0

    if [ -s "$domains".deadlist ]; then
        echo -n "-- Dead:            "
        removeDomains "$domains".deadlist "$domains"
        printDecCount
    fi

    # Add prioritized blocked Domains
    if [ -s "$block" ]; then
        cat <"$block" >>"$domains".prioblocklist
    fi
    getDomainsFromList "$prioblocklists" "$domains".prioblocklist 1 0

    if [ -s "$domains".prioblocklist ]; then
        echo -n "++ Block:           "
        addDomains "$domains".prioblocklist "$domains"
        printIncCount
    fi

    # Unblock prioritized whitelisted Domains
    if [ -s "$unblock" ]; then
        cat <"$unblock" >>"$domains".unblocklist
    fi
    getDomainsFromList "$unblocklists" "$domains".unblocklist 1 1

    if [ -s "$domains".unblocklist ]; then
        echo -n "-- Unblock:         "
        removeDomains "$domains".unblocklist "$domains"
        printDecCount
    fi

    # Unblock prioritized wildcard whitelisted Domains
    if [ -s "$unblock" ]; then
        cat <"$unblock" | grep -E '\*' >"$domains".unblocklist.wildcards.tmp
        convertWildcardToRegex "$domains".unblocklist.wildcards.tmp >>"$domains".unblocklist.wildcards
        rm -f "$domains".unblocklist.wildcards.tmp
    fi
    getRegexDomainsFromWilcardList "$unblocklists" "$domains".unblocklist.wildcards

    if [ -s "$domains".unblocklist.wildcards ]; then
        echo -n "-- Unblock(*):      "
        removeDomainsWildcard "$domains".unblocklist.wildcards "$domains"
        printDecCount
    fi

    # Extend by missing WWW/FLD Domains
    if inConfig "extendWWWFLD"; then
        if inConfig "white"; then
            echo -n "++ FLD from SLD:    "
            extendFLDfromSLD "$domains"
            printIncCount
        fi

        echo -n "++ FLD:             "
        extendFLD "$domains"
        printIncCount

        echo -n "++ WWW:             "
        extendWWW "$domains"
        printIncCount
    fi

    # Check if there are changes to the previous repo version
    getMd5 "$domains" >"$outdir"/md5.new
    if compareFiles "$outdir/md5.new" "$outdir/md5.old"; then
        echo ""
        echo "*****************************************************"
        echo "* No changes to the previous repo version detected! *"
        echo "*****************************************************"
        echo ""
        # Cleanup build out dir ...
        if inConfig "localpush"; then
            rm -f "$domains" "$hosts" "$adblock" "$stats"
        fi
        exit 0
    fi
    getMd5 "$domains" >"$outdir"/md5.old

    # Cleanup
    rm -f "$hosts" "$adblock"
    rm -f "$hosts".* "$adblock".*

    # Version
    echo ""
    echo "$cdo unique Domains - Version $version"
    echo "MD5 Domains RAW: $(getMd5 "$domains")"
    echo ""

    # Convert to Hostlist
    if inConfig "hosts"; then
        echo "# Convert $name to Hostlist ... "
        rm -f "$hosts"

        if ! inConfig "noheader"; then
            printHeader "$cdo" >"$hosts"
        fi

        sed -e 's/^/0.0.0.0 /' "$domains" >>"$hosts"
        echo ""
    fi

    # Convert to Adblocklist
    if inConfig "adblock"; then
        echo "# Convert $name to AdBlocklist ..."
        echo ""
        if [ ! -f "$json" ]; then
            cp $jsonbase "$json"
            sed -i "s/tmp/$name/g" "$json"
        fi

        if ! inConfig "no_adblock_convert"; then
            echo -n "Prepare domain list for compiling ... "
            if inConfig "adblock_important"; then
                cat <"$domains" | grep -Ev '^\s*$|^#|^!|^www\.' | sed -e 's/^/||/' | sed -e 's/$/^$important/' >"$adblock".raw
            else
                cat <"$domains" | grep -Ev '^\s*$|^#|^!|^www\.' | sed -e 's/^/||/' | sed -e 's/$/^/' >"$adblock".raw
            fi
            echo "done."
            echo ""
        fi

        cd "$outdir" || exit
        if inConfig "verbose"; then
            hostlist-compiler -v -c "$json" -o "$adblock"
        else
            hostlist-compiler -c "$json" -o "$adblock"
        fi
        rm -f "$adblock".raw
        cd "$sourcedir" || exit

        sortList "$adblock"

        if ! inConfig "noheader"; then
            c=$(grep -Evc '^\s*$|^#|^!' "$adblock")
            printHeader "$c" | sed 's/^\#/\!/' >"$adblock".tmp
        fi

        cat <"$adblock" | grep -Ev '^\s*$|^#|^!' >>"$adblock".tmp
        mv "$adblock".tmp "$adblock"

        if inConfig "adblocktowildcard"; then
            cat <"$adblock" | grep -Ev '^\s*$|^#|^!' | sed 's/||/*./' | sed 's/[\^]//g' >"$adblock".wildcards
        fi

        echo ""
    fi

    if ! inConfig "noheader"; then
        # Attach header
        echo "# Attach header to $name Domainlist ..."
        echo ""

        printHeader "$cdo" >"$domains".tmp
        cat <"$domains" >>"$domains".tmp
        mv "$domains".tmp "$domains"
    fi

    # Push to local repository
    if inConfig "localpush"; then
        echo "# Push $name to local Repositories ..."
        echo ""

        dos2unix -q "$outdir"/*

        if inConfig "white" || inConfig "dead"; then
            cp "$domains" "$repodata"/"$name".list
        elif inConfig "block"; then
            cp "$domains" "$repodata"/"$name".list.block
        elif inConfig "black"; then
            touch "$domains".whitelist.removed "$domains".wildcard.removed
            cp "$domains" "$repodata"/"$name".list
            cp "$domains".whitelist.removed "$repodata"/"$name".list.wl.removed
            cp "$domains".wildcard.removed "$repodata"/"$name".list.wc.removed
        else
            cp "$domains" "$repodomains"/"$name".txt
            cp "$stats" "$repodomains"

            if inConfig "hosts"; then
                cp "$hosts" "$repohosts"/"$name".txt
                cp "$stats" "$repohosts"
            fi

            if inConfig "adblock"; then
                cp "$adblock" "$repoadguard"/"$name".adblock
                cp "$stats" "$repoadguard"
            fi
        fi
    fi
) | tee "$stats"

# Cleanup build out dir if pushed
if inConfig "localpush"; then
    rm -f "$domains" "$hosts" "$adblock" "$stats"
fi

echo "End: $(date +'%Y.%m-%d-%H:%M:%S')"
echo ""

# Cleanup
rm -f "$header.ext"
#sortList $builddir/sourcefiles.txt

echo "$name - Done!"
echo ""
