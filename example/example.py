"""
This script requires libigl to run benchmarking
"""
import time
import numpy as np
import cyobj.io as mio
IGL_FOUND = False
try:
    import igl
    IGL_FOUND = True
except:
    print('igl not found. Not running benchmarks...')


def main():
    try:
        V, F, _, _ = mio.read_obj('nonexistent_file.obj')
    except FileNotFoundError:
        print('Successfully failed when nonexistent file is given')

    print('v only')
    V, F, VT, FT, VN, FN = mio.read_obj('resource/v.obj')
    print(V.shape)
    print(V)
    print(F.shape)
    print(F)
    print(VT.shape)
    print(VT)
    print(FT.shape)
    print(FT)
    print(VN.shape)
    print(VN)
    print(FN.shape)
    print(FN)

    print('v+vt')
    V, F, VT, FT, VN, FN = mio.read_obj('resource/v_vt.obj')
    print(V.shape)
    print(V)
    print(F.shape)
    print(F)
    print(VT.shape)
    print(VT)
    print(FT.shape)
    print(FT)
    print(VN.shape)
    print(VN)
    print(FN.shape)
    print(FN)

    print('v+vn')
    V, F, VT, FT, VN, FN = mio.read_obj('resource/v_vn.obj')
    print(V.shape)
    print(V)
    print(F.shape)
    print(F)
    print(VT.shape)
    print(VT)
    print(FT.shape)
    print(FT)
    print(VN.shape)
    print(VN)
    print(FN.shape)
    print(FN)


    print('v+vt+vn')
    V, F, VT, FT, VN, FN = mio.read_obj('resource/v_vt_vn.obj')
    print(V.shape)
    print(V)
    print(F.shape)
    print(F)
    print(VT.shape)
    print(VT)
    print(FT.shape)
    print(FT)
    print(VN.shape)
    print(VN)
    print(FN.shape)
    print(FN)

    print('wow_tex.obj with texture')
    mio.write_obj('wow_tex.obj', V, F, VT, FT, VN, FN, 'wow_tex.jpg')

    if IGL_FOUND:
        # On Ryzen 7 3950x
        # cython: 9.520554542541504 ms
        # igl(C++): 21.706414222717285 ms
        print('benchmark-read')
        start = time.time()
        for i in range(10):
            mio.read_obj('resource/v_vt_vn.obj')
        end = time.time()
        print('cython: {} ms'.format((end - start)*100))
        start = time.time()
        for i in range(10):
            igl.read_obj('resource/v_vt_vn.obj')
        end = time.time()
        print('igl: {} ms'.format((end - start)*100))

        # On Ryzen 7 3950x
        # cython: 8.391046524047852 ms
        # igl(C++): 10.899710655212402 ms
        print('benchmark-write')
        start = time.time()
        for i in range(10):
            mio.write_obj('resource/buffer.obj', V, F)
        end = time.time()
        print('cython: {} ms'.format((end - start)*100))
        start = time.time()
        for i in range(10):
            igl.write_obj('resource/buffer.obj', V, F)
        end = time.time()
        print('igl: {} ms'.format((end - start)*100))


if __name__ == '__main__':
    main()

