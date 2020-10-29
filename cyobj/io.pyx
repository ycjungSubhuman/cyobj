"""
Cython functions for IOs with intensive loop usage
"""

from libc.stdlib cimport atof, atoi
from libc.stdio cimport fopen, fclose, getc, rewind, FILE, fprintf, EOF, printf, fgets
from libc.string cimport strtok, strcmp
from cpython cimport array

import numpy as np

def read_obj(path):
    """
    Reads an .obj file.

    Note)
    * This function does not do sanity check. If given invalid format, may cause segmentation fault.
    * Face indices are zero-basd
    * If mixed triangle and quad appears, triangles are automatically converted to quads by repeating the last element

    Returns)
    V: vertex position (#V x 3)
    F: face indices for position (#F x #dim)
    VT: UV coordinate (#VT x 3)
    FT: face indices for UV coordinate (#F x #dim)
    VN: vertex normals (#VN x 3)
    FN: face indices for normals (#F x #dim)
    """
    cdef char v = b'v'[0]
    cdef char s = b' '[0]
    cdef char n = b'n'[0]
    cdef char t = b't'[0]
    cdef char f = b'f'[0]
    cdef char z = 0
    cdef char cz = b'0'[0]
    cdef char cn = b'9'[0]
    cdef char sl = b'/'[0]

    
    cdef int i, j
    cdef FILE* fin
    fin = fopen(path.encode(), "r")
    if fin == NULL:
        raise FileNotFoundError(2, "No file {}".format(path))
    cdef int c = getc(fin)
    cdef Py_ssize_t size_file = 0
    while c != EOF:
        size_file += 1
        c = getc(fin)
    cdef array.array orig = array.array('B')
    array.resize_smart(orig, size_file+1)
    cdef char[:] vorig = orig
    rewind(fin)
    for i in range(size_file):
        vorig[i] = getc(fin)
    vorig[size_file] = 0
    fclose(fin)

    cdef array.array buf = array.copy(orig)
    cdef char* pbuf = buf.data.as_chars

    cdef char* tok = strtok(pbuf, "\r\n")

    cdef Py_ssize_t size_v = 0
    cdef Py_ssize_t size_vt = 0
    cdef Py_ssize_t size_vn = 0
    cdef Py_ssize_t size_f = 0
    cdef Py_ssize_t dim_simplex = 0
    cdef Py_ssize_t cnt_face_attr = 0

    # Buffers for local inspection
    cdef int doubleslash_exists = 0
    cdef Py_ssize_t dim_simplex_local = 0
    cdef char* handle = tok
    cdef int kind = 0 # 0-> Nothing. 1->v, 2->vt, 3->vn, 4->f

    # Scan for buffer sizes
    while tok != NULL:
        kind = 0

        if tok[0] == v:
            if tok[1] == s:
                kind = 1
            elif tok[1] == t:
                kind = 2
            elif tok[1] == n:
                kind = 3
            else:
                kind = 0
        elif tok[0] == f:
            kind = 4

        if kind == 1:
            size_v += 1
        elif kind == 2:
            size_vt += 1
        elif kind == 3:
            size_vn += 1
        elif kind == 4:
            size_f += 1
            handle = tok
            cnt_face_attr = 0
            dim_simplex_local = 0
            while handle[0] != z:
                if handle[0] == sl and handle[1] != sl and handle[1] != z:
                    cnt_face_attr += 1
                elif handle[0] == s and handle[1] != s and handle[1] != z:
                    dim_simplex_local += 1
                elif handle[0] == sl and handle[1] == sl:
                    doubleslash_exists = 1
                handle += 1
            if dim_simplex_local > dim_simplex:
                dim_simplex = dim_simplex_local
            cnt_face_attr = 1 + (cnt_face_attr // dim_simplex)

        tok = strtok(NULL, b"\r\n")

    cdef int ft_exists = ((cnt_face_attr == 2) and (not doubleslash_exists)) or (cnt_face_attr == 3)
    cdef int fn_exists = ((cnt_face_attr == 2) and doubleslash_exists) or (cnt_face_attr == 3)

    # Allocate buffers
    V = np.zeros((size_v, 3), dtype=np.float)
    VT = np.zeros((size_vt, 2), dtype=np.float)
    VN = np.zeros((size_vn, 3), dtype=np.float)
    F = np.zeros((size_f, dim_simplex), dtype=np.int)
    
    if ft_exists > 0:
        FT = np.zeros((size_f, dim_simplex), dtype=np.int)
    else:
        FT = np.zeros((0, dim_simplex), dtype=np.int)

    if fn_exists > 0:
        FN = np.zeros((size_f, dim_simplex), dtype=np.int)
    else:
        FN = np.zeros((0, dim_simplex), dtype=np.int)

    cdef double[:,:] vV = V
    cdef double[:,:] vVT = VT
    cdef double[:,:] vVN = VN
    cdef long[:,:] vF = F
    cdef long[:,:] vFT = FT
    cdef long[:,:] vFN = FN

    # Fill in buffers
    buf = array.copy(orig)
    pbuf = buf.data.as_chars
    tok = strtok(pbuf, b" \r\n/")

    cdef int mode = 0
    cdef int cnt = 0
    cdef int row_v = 0
    cdef int row_vt = 0
    cdef int row_vn = 0
    cdef int row_f = 0
    cdef int num_f_entry = cnt_face_attr * dim_simplex

    while tok != NULL:
        if mode == 1:
            if cnt > 2:
                mode = 0
                row_v += 1
            else:
                vV[row_v, cnt] = atof(tok)
                cnt += 1
        elif mode == 2:
            if cnt > 1:
                mode = 0
                row_vt += 1
            else:
                vVT[row_vt, cnt] = atof(tok)
                cnt += 1
        elif mode == 3:
            if cnt > 2:
                mode = 0
                row_vn += 1
            else:
                vVN[row_vn, cnt] = atof(tok)
                cnt += 1
        elif mode == 4:
            if cnt >= num_f_entry:
                mode = 0
                row_f += 1
            elif tok[0] < cz or tok[0] > cn: # mixed triangle and quad
                # Repeat last elements
                vF[row_f, cnt//cnt_face_attr] = vF[row_f, cnt//cnt_face_attr - 1] 
                if ft_exists:
                    vFT[row_f, cnt//cnt_face_attr] = vFT[row_f, cnt//cnt_face_attr - 1]
                if fn_exists:
                    vFN[row_f, cnt//cnt_face_attr] = vFN[row_f, cnt//cnt_face_attr - 1]
                mode = 0
                row_f += 1
            elif cnt % cnt_face_attr == 0:
                vF[row_f, cnt//cnt_face_attr] = atoi(tok) - 1
            elif cnt % cnt_face_attr == 1 and (not doubleslash_exists):
                vFT[row_f, cnt//cnt_face_attr] = atoi(tok) - 1
            elif (cnt % cnt_face_attr == 2 and (not doubleslash_exists)) or (cnt % cnt_face_attr == 1 and doubleslash_exists):
                vFN[row_f, cnt//cnt_face_attr] = atoi(tok) - 1
            cnt += 1

        if tok[0] == v:
            if tok[1] == z:
                mode = 1
                cnt = 0
            elif tok[1] == t:
                mode = 2
                cnt = 0
            elif tok[1] == n:
                mode = 3
                cnt = 0
            else:
                mode = 0
                cnt = 0
        elif tok[0] == f and tok[1] == z:
            mode = 4
            cnt = 0

        tok = strtok(NULL, b" \r\n/")

    return V, F, VT, FT, VN, FN


def write_obj(path, double[:,:] V, long[:,:] F, double[:,:] VT=None, long[:,:] FT=None, double[:,:] VN=None, long[:,:] FN=None, path_img=None):
    """
    Writes an .obj file.
    Optionally a .mtl file if path_img is given.

    path: .obj fiel path
    V: vertex position (#V x 3)
    F: face indices for position (#F x #dim)
    VT: (Optional) UV coordinate (#VT x 3)
    FT: (Optional) face indices for UV coordinate (#F x #dim)
    VN: (Optional) vertex normals (#VN x 3)
    FN: (Optional) face indices for normals (#F x #dim)
    path_img: Texture image path
    """
    cdef int i,j
    cdef FILE* fout
    cdef bytes cpath_mtl
    cdef bytes cpath_img
    cdef bytes template = b"""newmtl material
Ka 1.000 1.000 1.000
Kd 1.000 1.000 1.000
Ks 0.000 0.000 0.000
d 1.0
illum 1
map_Ka %s
map_Kd %s
        """
    fout = fopen(path.encode(), "w")
    if fout == NULL:
        raise FileNotFoundError(2, "Cannot write file {}".format(path))
    
    if path_img is not None:
        path_mtl = path.replace('.obj', '.mtl')
        cpath_img = path_img.encode()
        cpath_mtl = path_mtl.encode()
        fprintf(fout, b"mtllib %s\nusemtl material\n", cpath_mtl)
        fmtl = fopen(cpath_mtl, "w")
        if fmtl == NULL:
            raise FileNotFoundError(2, "Cannot write file {}".format(path_mtl))
        fprintf(fmtl, template, cpath_img, cpath_img)
        fclose(fmtl)

    for i in range(V.shape[0]):
        fprintf(fout, b"v %f %f %f\n", V[i,0], V[i,1], V[i,2])

    if VT is not None:
        for i in range(VT.shape[0]):
            fprintf(fout, b"vt %f %f\n", VT[i,0], VT[i,1])

    if VN is not None:
        for i in range(VN.shape[0]):
            fprintf(fout, b"vn %f %f %f\n", VN[i,0], VN[i,1], VN[i,2])

    cdef write_ft = FT is not None
    cdef write_fn = FN is not None

    for i in range(F.shape[0]):
        fprintf(fout, b"f ")
        for j in range(F.shape[1]):
            if j == 3 and F[i,j] == F[i,j-1]: # Duplicate indices introduced by mixed triangle/quad
                    break

            if write_ft and write_fn:
                fprintf(fout, b"%ld/%ld/%ld ", F[i,j]+1, FT[i,j]+1 , FN[i,j]+1 )
            elif write_ft and not write_fn:
                fprintf(fout, b"%ld/%ld ", F[i,j]+1 , FT[i,j]+1 )
            elif not write_ft and write_fn:
                fprintf(fout, b"%ld//%ld ", F[i,j]+1 , FN[i,j]+1 )
            else:
                fprintf(fout, b"%ld ", F[i,j]+1 )
        fprintf(fout, b"\n")

    fclose(fout)