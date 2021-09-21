from setuptools import setup
from Cython.Build import cythonize

setup(
    name='cyobj',
    description='A fast and Wavefront .OBJ reader/writer',
    version="0.2.3",
    author='Yucheol Jung',
    author_email='ycjung@postech.ac.kr',
    packages=['cyobj'],
    url='https://github.com/ycjungSubhuman/cyobj',
    ext_modules=cythonize("cyobj/detail/io.pyx",
                          compiler_directives={'language_level': "3"}),
)
