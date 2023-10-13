# cython: language_level=3
# cython: linetrace=True
# -*- coding: utf-8 -*-
# *****************************************************************************
# Copyright (c) 2016-2023, Intel Corporation
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
# *****************************************************************************

"""Module Backend (Array manipulation routines)

This module contains interface functions between C backend layer
and the rest of the library

"""

# NO IMPORTs here. All imports must be placed into main "dpnp_algo.pyx" file

__all__ += [
    "dpnp_repeat",
]


# C function pointer to the C library template functions
ctypedef c_dpctl.DPCTLSyclEventRef(*fptr_dpnp_repeat_t)(c_dpctl.DPCTLSyclQueueRef,
                                                        const void *, void * , const size_t , const size_t,
                                                        const c_dpctl.DPCTLEventVectorRef)


cpdef utils.dpnp_descriptor dpnp_repeat(utils.dpnp_descriptor array1, repeats, axes=None):
    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(array1.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_REPEAT_EXT, param1_type, param1_type)

    array1_obj = array1.get_array()

    # create result array with type given by FPTR data
    cdef shape_type_c result_shape = (array1.size * repeats, )
    cdef utils.dpnp_descriptor result = utils.create_output_descriptor(result_shape,
                                                                       kernel_data.return_type,
                                                                       None,
                                                                       device=array1_obj.sycl_device,
                                                                       usm_type=array1_obj.usm_type,
                                                                       sycl_queue=array1_obj.sycl_queue)
    result_sycl_queue = result.get_array().sycl_queue

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> result_sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef fptr_dpnp_repeat_t func = <fptr_dpnp_repeat_t > kernel_data.ptr
    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    array1.get_data(),
                                                    result.get_data(),
                                                    repeats,
                                                    array1.size,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)

    return result
