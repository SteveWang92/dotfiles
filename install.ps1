$CONFIG = "install.conf.yaml"
$DOTBOT_DIR = "dotbot"
$DOTBOT_BIN = "bin/dotbot"
$BASEDIR = $PSScriptRoot

Set-Location $BASEDIR
git -C $BASEDIR submodule sync --quiet --recursive
git -C $BASEDIR submodule update --init --recursive

foreach ($PYTHON in ('python', 'python3')) {
    if (Get-Command $PYTHON -ErrorAction SilentlyContinue) {
        # Resolve the real interpreter: the Python 3.14+ Windows shim does its own
        # shebang handling and cannot run dotbot's sh/python polyglot entry point.
        $PYEXE = &$PYTHON -c "import sys; print(sys.executable)"
        &$PYEXE (Join-Path $BASEDIR $DOTBOT_DIR $DOTBOT_BIN) -d $BASEDIR -c $CONFIG $Args
        return
    }
}
Write-Error "Error: Cannot find Python."
