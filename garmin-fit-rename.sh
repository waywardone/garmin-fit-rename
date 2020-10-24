#!/usr/bin/env bash

fr235() {
	local fitname=$1
    # Establish current millennium and century to add to a Garmin single digit year number

    YEAR=$(date +%Y)
    YEARM=${YEAR:0:1}
    YEARC=${YEAR:1:1}
    YEARD=${YEAR:2:1}
    YEARMC=$YEARM$YEARC
    #YEARMCD=$YEARM$YEARC$YEARD
    declare -A gcharmap

    c=0
    for i in {0..9}; do
        gcharmap["$i"]="$i"
        c=$((c+1))
    done

    for i in {A..Z}; do
        gcharmap["$i"]=$c
        c=$((c+1))
    done

    #for k in ${!gcharmap[@]}; do echo "$k - ${gcharmap[$k]}"; done
    newfname=$YEARMC

    n=0
    while test $n -lt 8; do
        gchar=${fitname:$n:1}
        nchar=${gcharmap[$gchar]}

        if [[ $n == 3 ]]; then
            newfname+="-"
        fi

        # 1st character is the year
        if [[ $n == 0 && ${nchar} -lt 10 ]]; then
            newfname+="1${nchar}"
        elif [[ $n == 0 && ${nchar} -ge 10 ]]; then
            newfname+="2$(( nchar % 10 ))"
        elif [[ ( $n == 1 || $n == 2 || $n == 3 ) && ${nchar} -lt 10 ]]; then
            newfname+="0${nchar}"
        elif [[ $n == 4 || $n == 5 || $n == 6 || $n == 7 ]]; then
            newfname+=$gchar
        else
            newfname+="${nchar}"
        fi

        n=$(($n+1))
    done
    echo $newfname
}

main() {
    while getopts "h?s:" opt; do
        case "$opt" in
        h|\?)
            echo "Usage: $0 -s /path/to/dir/with/fit/files"
            exit 0
            ;;
        s)  SRCDIR=$OPTARG
            ;;
        esac
    done

    shift $((OPTIND-1))

    if [[ -z $SRCDIR || ! -d $SRCDIR ]]; then
        echo "Specify a directory with FIT files."
        exit 1
    fi

    case $OSTYPE in
        darwin*)
            DESTDIR="/Users/$USER"
        ;;
        linux*)
            DESTDIR="/home/$USER"
        ;;
        *)
            echo "Unknown OSTYPE: $OSTYPE"
            exit 1
        ;;
    esac

    TSTAMP=$(date +%Y%m%d-%H%M%S)
    DESTDIR="$DESTDIR/$TSTAMP-Garmin"

    for f in $(find $SRCDIR/ -iname '*.fit' )
    do
        basename=${f##*/}

        # Example: 2019-09-01-06-40-57.fit
        FR645Pattern="([0-9]{4})\-([0-9]{2})\-([0-9]{2})\-([0-9]{2})\-([0-9]{2})\-([0-9]{2})\.([Ff][Ii][Tt])"
        # Example: 96FG1906.FIT
        FR235Pattern="([0-9A-Z]{1}[1-9ABC]{1}[1-9A-V]{1}[1-9A-N]{1}[0-9]{4})\.([Ff][Ii][Tt])"

        if [[ $basename =~ $FR645Pattern ]]; then
            Y=${BASH_REMATCH[1]}
            m=${BASH_REMATCH[2]}
            d=${BASH_REMATCH[3]}
            H=${BASH_REMATCH[4]}
            M=${BASH_REMATCH[5]}
            S=${BASH_REMATCH[6]}
            E="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[7]}")"
            newName="$Y$m$d-$H$M$S.$E"
        elif [[ $basename =~ $FR235Pattern ]]; then
            O=${BASH_REMATCH[1]}
            E="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[2]}")"
            newName=$(fr235 $basename)
            newName+="-$O.$E"
        else
            echo "Don't know how to process $basename"
            continue
        fi
        mkdir -p $DESTDIR/${newName:0:4}
        echo "$basename -> $DESTDIR/${newName:0:4}/$newName"
        cp -af $f $DESTDIR/${newName:0:4}/$newName
    done
}

main "$@"

