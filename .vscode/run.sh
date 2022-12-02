# https://github.com/MarcinKonowalczyk/run_sh
# Pass over to nim script asap

if ! command -v nim &> /dev/null; then
    echo "nim could not be found"
    exit
fi

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
nim --verbosity:0 "$ROOT/run.nims" "$1"