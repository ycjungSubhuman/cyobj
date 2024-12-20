# Cyobj

[![PyPI version](https://badge.fury.io/py/cyobj.svg)](https://badge.fury.io/py/cyobj)

A python library for Wavefront .OBJ reading/writing

Why did we write yet another .obj reader/writer?

Many python libraries for .obj do not support 

* Texture coodinates
* Vertex normals
* Mixed quad/triangle
* Automatic generation of .mtl file when texture map exists
* Fast read/write

Therefore we wrote one ourselves that supports them all.

## Requirement

* NumPy
* Cython

## Install

### From PyPI

`pip install cyobj`

### Build yourself

`python setup.py build && python setup.py install`

## Running time

Compared to libigl-python-binding,

### Reading

Reads a large .obj (Armadillo) file with V/VT/VN attributes

* cyobj: around 465 ms
* igl(C++): round 1043 ms

### Writing

Writes an .obj file with V attributes

* cyobj: around 252 ms
* igl(C++): around 362 ms

## Note

This library does not fully support polygon meshes. It only supports fixed quad and triangles.
When mixed quad and triangles are detected, F array has 4 columns, and the last column is the copy of the previous column.


