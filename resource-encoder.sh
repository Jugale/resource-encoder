#/bin/bash

function print_help {
    echo "Usage: $(basename "$0") <Input.xxx> <Output.swift>"
    echo "Or, simply 'bash /path/to/$(basename "$0")' in an Xcode runscript phase with input and output files "
}

function get_classname {
    local CLASSNAME=$(basename -- "$1")
    local CLASSNAME="${CLASSNAME%.*}"
    local CLASSNAME="${CLASSNAME//[^[:alnum:]]/_}"
    echo "$CLASSNAME"
}

# Gets the Swift string type of the file
function get_filetype {
    local INPUT="$1"
    local TYPE=$(file -b "$INPUT")

    case "$TYPE" in
        *"ASCII text"*)
            echo "ascii";;
        *"UTF-8 Unicode text"*)
            echo "utf8";;
        *)
            echo "unknown file encoding" && exit 4;;
    esac
}

# Gets a byte-array representation of the file
function get_bytes {
    local INPUT="$1"
    local BYTE_ARRAY=$(cat "$INPUT" | xxd -pu -c 999 | sed 's/.\{2\}/0x&, /g')
    echo "$BYTE_ARRAY"
}

function verify_input {
    local INPUT="$1"
    if [ ! -f "$INPUT" ]; then
        echo "'$INPUT' does not exist"
        print_help
        exit 1
    fi 
}

function verify_output {
    local OUTPUT="$1"
    if [ "${OUTPUT##*.}" != "swift" ]; then 
        echo "'$OUTPUT' must have the extension .swift"
        print_help
        exit 2
    fi
}

function generate {
    local INPUT=$1
    local OUTPUT=$2

    verify_input "$INPUT"
    verify_output "$OUTPUT"
    
    local CLASSNAME=$(get_classname "$OUTPUT")
    local BYTE_ARRAY=$(get_bytes "$INPUT")
    local TYPE=$(get_filetype "$INPUT")

    echo "Generating $OUTPUT from $INPUT"

    cat <<EOF > "$OUTPUT"
import Foundation

struct $CLASSNAME {

    static func string() -> String {
        return String(data: data(), encoding: .$TYPE)!
    }

    static func data() -> Data {
        var bytes = self.bytes()
        bytes.removeLast()
        return Data(bytes: bytes, count: bytes.count)
    }

    // Contains an extra 0x0 at the end to prevent reading of the array running into random memory
    private static func bytes() -> [UInt8] {
        return [${BYTE_ARRAY}0x0]
    }
}
EOF
}

if [ -n "$SCRIPT_INPUT_FILE_COUNT" ]; then
    # We are in an Xcode runscript phase and there are input fules
    COUNTER=0
    while [ $COUNTER -lt ${SCRIPT_INPUT_FILE_COUNT} ]; do
        tmp="SCRIPT_INPUT_FILE_$COUNTER"
        INPUT=${!tmp}
        tmp="SCRIPT_OUTPUT_FILE_$COUNTER"
        OUTPUT=${!tmp}

        generate "$INPUT" "$OUTPUT"

        let COUNTER=COUNTER+1
    done
else
    INPUT=$1
    OUTPUT=$2
    generate "$INPUT" "$OUTPUT"
fi

