# Copyright (c) 2017-2021 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# It defines the following variables:
#     TBB_<component>_FOUND
#     TBB_IMPORTED_TARGETS
#
# TBBConfigVersion.cmake defines TBB_VERSION
#
# Initialize to default values
if (NOT TBB_IMPORTED_TARGETS)
    set(TBB_IMPORTED_TARGETS "")
endif()

if (NOT TBB_FIND_COMPONENTS)
    set(TBB_FIND_COMPONENTS "tbb;tbbmalloc;tbbmalloc_proxy")
    foreach (_tbb_component ${TBB_FIND_COMPONENTS})
        set(TBB_FIND_REQUIRED_${_tbb_component} 1)
    endforeach()
endif()

get_filename_component(_tbb_root "${CMAKE_CURRENT_LIST_DIR}" REALPATH)
get_filename_component(_tbb_root "${_tbb_root}/../../.." ABSOLUTE)

set(TBB_INTERFACE_VERSION )

set(_tbb_bin_version 12)
set(_tbbmalloc_bin_version 2)
set(_tbbmalloc_proxy_bin_version 2)
set(_tbbbind_bin_version 3)

# Add components with internal dependencies: tbbmalloc_proxy -> tbbmalloc
list(FIND TBB_FIND_COMPONENTS tbbmalloc_proxy _tbbmalloc_proxy_ix)
if (NOT _tbbmalloc_proxy_ix EQUAL -1)
    list(APPEND TBB_FIND_COMPONENTS tbbmalloc)
    list(REMOVE_DUPLICATES TBB_FIND_COMPONENTS)
    set(TBB_FIND_REQUIRED_tbbmalloc ${TBB_FIND_REQUIRED_tbbmalloc_proxy})
endif()
unset(_tbbmalloc_proxy_ix)

if (CMAKE_SIZEOF_VOID_P STREQUAL "8")
    set(_tbb_subdir intel64/gcc4.8)
else ()
    set(_tbb_subdir ia32/gcc4.8)
endif()

foreach (_tbb_component ${TBB_FIND_COMPONENTS})
    set(TBB_${_tbb_component}_FOUND 0)

    find_library(_tbb_release_lib lib${_tbb_component}${_bin_version}.so.${_${_tbb_component}_bin_version}
                  PATHS ${_tbb_root}
                  HINTS ENV TBB_ROOT_HINT
                  PATH_SUFFIXES "lib" "lib/${_tbb_subdir}")

    if (NOT TBB_FIND_RELEASE_ONLY)
        find_library(_tbb_debug_lib lib${_tbb_component}${_bin_version}_debug.so.${_${_tbb_component}_bin_version}
                     PATHS ${_tbb_root}
                     HINTS ENV TBB_ROOT_HINT
                     PATH_SUFFIXES "lib" "lib/${_tbb_subdir}")
    endif()

    if (EXISTS "${_tbb_release_lib}" OR EXISTS "${_tbb_debug_lib}")
        if (NOT TARGET TBB::${_tbb_component})
            add_library(TBB::${_tbb_component} SHARED IMPORTED)

	    find_path(_tbb_include_dir
	      oneapi/tbb.h
	      PATHS ${_tbb_root}
	      PATH_SUFFIXES include
	      HITNS ENV TBB_ROOT_HINT
	      )
	    
            set_target_properties(TBB::${_tbb_component} PROPERTIES
                                  INTERFACE_INCLUDE_DIRECTORIES "${_tbb_include_dir}")
            unset(_tbb_current_realpath)
            unset(_tbb_include_dir)

            if (EXISTS "${_tbb_release_lib}")
                set_target_properties(TBB::${_tbb_component} PROPERTIES
                                      IMPORTED_LOCATION_RELEASE "${_tbb_release_lib}")
                set_property(TARGET TBB::${_tbb_component} APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
            endif()

            if (EXISTS "${_tbb_debug_lib}")
                set_target_properties(TBB::${_tbb_component} PROPERTIES
                                      IMPORTED_LOCATION_DEBUG "${_tbb_debug_lib}")
                set_property(TARGET TBB::${_tbb_component} APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
            endif()

            # Add internal dependencies for imported targets: TBB::tbbmalloc_proxy -> TBB::tbbmalloc
            if (_tbb_component STREQUAL tbbmalloc_proxy)
                set_target_properties(TBB::tbbmalloc_proxy PROPERTIES INTERFACE_LINK_LIBRARIES TBB::tbbmalloc)
            endif()
        endif()
        list(APPEND TBB_IMPORTED_TARGETS TBB::${_tbb_component})
        set(TBB_${_tbb_component}_FOUND 1)
    elseif (TBB_FIND_REQUIRED AND TBB_FIND_REQUIRED_${_tbb_component})
        message(STATUS "Missed required oneTBB component: ${_tbb_component}")
        if (TBB_FIND_RELEASE_ONLY)
            message(STATUS "  ${_tbb_release_lib} must exist.")
        else()
            message(STATUS "  one or both of:\n   ${_tbb_release_lib}\n    ${_tbb_debug_lib}\n   files must exist.")
        endif()
        set(TBB_FOUND FALSE)
    endif()
endforeach()
list(REMOVE_DUPLICATES TBB_IMPORTED_TARGETS)
unset(_tbb_release_lib)
unset(_tbb_debug_lib)
unset(_tbb_root)
