trap 'die "${_t} failed"' ERR
for _t in unittests/test_*.py;
    do epytest "${_t}"
done
