REM A workaround for activate-dpcpp.bat issue to be addressed in 2021.4
set "LIB=%BUILD_PREFIX%\Library\lib;%BUILD_PREFIX%\compiler\lib;%LIB%"
SET "INCLUDE=%BUILD_PREFIX%\include;%INCLUDE%"

REM Since the 60.0.0 release, setuptools includes a local, vendored copy
REM of distutils (from late copies of CPython) that is enabled by default.
REM It breaks build for Windows, so use distutils from "stdlib" as before.
REM @TODO: remove the setting, once transition to build backend on Windows
REM to cmake is complete.
SET "SETUPTOOLS_USE_DISTUTILS=stdlib"

"%PYTHON%" setup.py clean --all

set "MKLROOT=%PREFIX%/Library"
set "TBB_ROOT_HINT=%PREFIX%/Library"
set "DPL_ROOT_HINT=%PREFIX%/Library"

%PYTHON% -m dpctl --cmakedir > Output
set /p DPCTL_CMAKE_DIR= < Output

set "SKBUILD_ARGS=-G Ninja -- -DCMAKE_C_COMPILER:PATH=icx -DCMAKE_CXX_COMPILER:PATH=icx -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
set "SKBUILD_ARGS=%SKBUILD_ARGS% -DDPCTL_MODULE_PATH:PATH=%DPCTL_CMAKE_DIR% "
set "SKBUILD_ARGS=%SKBUILD_ARGS% -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"

FOR %%V IN (14.0.0 14 15.0.0 15 16.0.0 16 17.0.0 17) DO @(
  REM set DIR_HINT if directory exists
  IF EXIST "%BUILD_PREFIX%\Library\lib\clang\%%V\" (
     SET "SYCL_INCLUDE_DIR_HINT=%BUILD_PREFIX%\Library\lib\clang\%%V"
  )
)

set "PATCHED_CMAKE_VERSION=3.26"
set "PLATFORM_DIR=%PREFIX%\Library\share\cmake-%PATCHED_CMAKE_VERSION%\Modules\Platform"
set "FN=Windows-IntelLLVM.cmake"

rem Save the original file, and copy patched file to
rem fix the issue with IntelLLVM integration with cmake on Windows
if EXIST "%PLATFORM_DIR%" (
  dir "%PLATFORM_DIR%\%FN%"
  copy /Y "%PLATFORM_DIR%\%FN%" .
  if errorlevel 1 exit 1
  copy /Y ".github\workflows\Windows-IntelLLVM_%PATCHED_CMAKE_VERSION%.cmake" "%PLATFORM_DIR%\%FN%"
  if errorlevel 1 exit 1
)

if NOT "%WHEELS_OUTPUT_FOLDER%"=="" (
    rem Install and assemble wheel package from the build bits
    "%PYTHON%" setup.py install bdist_wheel %SKBUILD_ARGS%
    if errorlevel 1 exit 1
    copy dist\dpnp*.whl %WHEELS_OUTPUT_FOLDER%
    if errorlevel 1 exit 1
) ELSE (
    rem Only install
    "%PYTHON%" setup.py install %SKBUILD_ARGS%
    if errorlevel 1 exit 1
)

rem copy back
if EXIST "%PLATFORM_DIR%" (
   copy /Y "%FN%" "%PLATFORM_DIR%\%FN%"
   if errorlevel 1 exit 1
)
