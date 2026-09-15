#!/usr/bin/env bash
# Execute the workshop notebooks to check that they run without errors.
#
# Usage:
#   ./run_notebooks.sh                    # run all notebooks
#   ./run_notebooks.sh path/to/nb.ipynb   # run selected notebooks only

set -uo pipefail

cd "$(dirname "$0")"

# Order matters: 1D_boreholes loads inv_ERT.vtk and inv_SRT.vtk written by the
# two manager notebooks.
NOTEBOOKS=(
    01_introduction/ERT_manager.ipynb
    01_introduction/SRT_manager.ipynb
    01_introduction/1D_boreholes.ipynb
    03_joint_inversion/JI_field_data.ipynb
)
[ $# -gt 0 ] && NOTEBOOKS=("$@")

# pyGIMLi's C++ core writes to stdout while holding the GIL. With ipykernel's
# default output capturing, the kernel then deadlocks silently once the capture
# pipe is full. Disable it with a temporary IPython profile, so the kernel
# output is printed directly to the terminal instead.
export IPYTHONDIR=$(mktemp -d)
trap 'rm -rf "$IPYTHONDIR"' EXIT
mkdir -p "$IPYTHONDIR/profile_default"
echo "c.IPKernelApp.capture_fd_output = False" \
    > "$IPYTHONDIR/profile_default/ipython_kernel_config.py"

export MPLBACKEND=Agg  # no plot windows

fmt_time() { printf '%d:%02d' $(($1 / 60)) $(($1 % 60)); }

results=()
failed=0

for nb in "${NOTEBOOKS[@]}"; do
    echo "==> Running $nb"
    start=$SECONDS
    if jupyter execute "$nb"; then
        status=PASS
    else
        status=FAIL
        failed=$((failed + 1))
    fi
    elapsed=$(fmt_time $((SECONDS - start)))
    echo "==> $status $nb ($elapsed)"
    results+=("  $status  $nb ($elapsed)")
done

echo
echo "Summary: $failed of ${#NOTEBOOKS[@]} failed, total time $(fmt_time $SECONDS)"
printf '%s\n' "${results[@]}"

[ $failed -eq 0 ]
