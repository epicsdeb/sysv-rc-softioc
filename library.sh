
CONF="${CONF:-/etc/default/epics-softioc}"

requireroot() {
	[ "`id -u`" -eq 0 ] || die "This action requires root access"
}

# Must run this before calling any of the below
# Sets: $IOCPATH
iocinit() {
	CONF=/etc/default/epics-softioc
	[ -f "$CONF" ] || die "Missing $CONF"
	. "$CONF"
	[ -z "$SOFTBASE" ] && die "SOFTBASE not set in $CONF"
	IOCPATH=/etc/iocs
	if [ -n "$SOFTBASE" ]
	then
		# Search in system locations first then user locations
		IOCPATH="$IOCPATH:$SOFTBASE"
	fi
}

# $1 /base/dir/and/iocname
loadconfig() {
    IOC="`basename $1`"
    BASE="`dirname $1`"
    if [ ! -r "$1/config" ]; then
        echo "Missing config $1/config" >&2
        return 1
    fi
    unset EXEC USER HOST
    PORT=0
    local INSTBASE="$1"
    . "$1/config"
}

#   Run command $1 on IOC all instances
# $1 - A shell command
# $2 - IOC name (empty for all IOCs)
visit() {
	[ -z "$1" ] && die "visitall: missing argument"
	vcmd="$1"
	vname="$2"
	shift
	shift

	save_IFS="$IFS"
	IFS=':'
	for ent in $IOCPATH
	do
		IFS="$save_IFS"
		[ -z "$ent" -o ! -d "$ent" ] && continue

		for iocconf in "$ent"/*/config
		do
			ioc="`dirname "$iocconf"`"
			name="`basename "$ioc"`"
			[ "$name" = '*' ] && continue

			if [ -z "$vname" ] || [ "$name" = "$vname" ]; then
				$vcmd $ioc "$@"
			fi
		done
	done
}

#   Find the location of an IOC
#   prints a single line which is a directory
#   which contains '$IOC/config'
# $1 - IOC name
findbase() {
	[ -z "$1" ] && die "visitall: missing argument"
	IOC="$1"

	save_IFS="$IFS"
	IFS=':'
	for ent in $IOCPATH
	do
		IFS="$save_IFS"
		[ -z "$ent" -o ! -d "$ent" ] && continue

		if [ -f "$ent/$IOC/config" ]; then
			printf "$ent"
			return 0
		fi
	done
	return 1
}
