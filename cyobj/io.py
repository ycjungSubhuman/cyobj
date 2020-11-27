import cyobj.detail.io as dio


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
    return dio.read_obj(path)


def write_obj(path, V, F, VT=None, FT=None, VN=None, FN=None, path_img=None):
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
    dio.write_obj(path, V, F, VT, FT, VN, FN, path_img)
