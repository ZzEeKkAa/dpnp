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

"""Module Backend (Indexing part)

This module contains interface functions between C backend layer
and the rest of the library

"""

# NO IMPORTs here. All imports must be placed into main "dpnp_algo.pyx" file

__all__ += [
    "dpnp_choose",
    "dpnp_diag_indices",
    "dpnp_diagonal",
    "dpnp_fill_diagonal",
    "dpnp_indices",
    "dpnp_put",
    "dpnp_put_along_axis",
    "dpnp_putmask",
    "dpnp_select",
    "dpnp_take",
    "dpnp_take_along_axis",
    "dpnp_tril_indices",
    "dpnp_tril_indices_from",
    "dpnp_triu_indices",
    "dpnp_triu_indices_from"
]

ctypedef c_dpctl.DPCTLSyclEventRef(*fptr_dpnp_choose_t)(c_dpctl.DPCTLSyclQueueRef,
                                                        void *, void * , void ** , size_t, size_t, size_t,
                                                        const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*fptr_dpnp_diag_indices)(c_dpctl.DPCTLSyclQueueRef,
                                                            void * , size_t,
                                                            const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*custom_indexing_2in_1out_func_ptr_t)(c_dpctl.DPCTLSyclQueueRef,
                                                                         void *,
                                                                         const size_t,
                                                                         void * ,
                                                                         void * ,
                                                                         size_t,
                                                                         const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*custom_indexing_2in_1out_func_ptr_t_)(c_dpctl.DPCTLSyclQueueRef,
                                                                          void * ,
                                                                          const size_t,
                                                                          void * ,
                                                                          const size_t,
                                                                          shape_elem_type * ,
                                                                          shape_elem_type *,
                                                                          const size_t,
                                                                          const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*custom_indexing_2in_func_ptr_t)(c_dpctl.DPCTLSyclQueueRef,
                                                                    void *, void * , shape_elem_type * , const size_t,
                                                                    const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*custom_indexing_3in_with_axis_func_ptr_t)(c_dpctl.DPCTLSyclQueueRef,
                                                                              void * ,
                                                                              void * ,
                                                                              void * ,
                                                                              const size_t,
                                                                              shape_elem_type * ,
                                                                              const size_t,
                                                                              const size_t,
                                                                              const size_t,
                                                                              const c_dpctl.DPCTLEventVectorRef)
ctypedef c_dpctl.DPCTLSyclEventRef(*custom_indexing_6in_func_ptr_t)(c_dpctl.DPCTLSyclQueueRef,
                                                                    void *,
                                                                    void * ,
                                                                    void * ,
                                                                    const size_t,
                                                                    const size_t,
                                                                    const size_t,
                                                                    const c_dpctl.DPCTLEventVectorRef)


cpdef utils.dpnp_descriptor dpnp_choose(utils.dpnp_descriptor x1, list choices1):
    cdef vector[void * ] choices
    cdef utils.dpnp_descriptor choice
    for desc in choices1:
        choice = desc
        choices.push_back(choice.get_data())

    cdef shape_type_c x1_shape = x1.shape
    cdef size_t choice_size = choices1[0].size

    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(x1.dtype)

    cdef DPNPFuncType param2_type = dpnp_dtype_to_DPNPFuncType(choices1[0].dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_CHOOSE_EXT, param1_type, param2_type)

    x1_obj = x1.get_array()

    cdef utils.dpnp_descriptor res_array = utils.create_output_descriptor(x1_shape,
                                                                          kernel_data.return_type,
                                                                          None,
                                                                          device=x1_obj.sycl_device,
                                                                          usm_type=x1_obj.usm_type,
                                                                          sycl_queue=x1_obj.sycl_queue)

    result_sycl_queue = res_array.get_array().sycl_queue

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> result_sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef fptr_dpnp_choose_t func = <fptr_dpnp_choose_t > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    res_array.get_data(),
                                                    x1.get_data(),
                                                    choices.data(),
                                                    x1_shape[0],
                                                    choices.size(),
                                                    choice_size,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)

    return res_array


cpdef tuple dpnp_diag_indices(n, ndim):
    cdef size_t res_size = 0 if n < 0 else n

    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(dpnp.int64)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_DIAG_INDICES_EXT, param1_type, param1_type)

    cdef fptr_dpnp_diag_indices func = <fptr_dpnp_diag_indices > kernel_data.ptr

    cdef c_dpctl.SyclQueue q
    cdef c_dpctl.DPCTLSyclQueueRef q_ref
    cdef c_dpctl.DPCTLSyclEventRef event_ref

    res_list = []
    cdef utils.dpnp_descriptor res_arr
    cdef shape_type_c result_shape = utils._object_to_tuple(res_size)
    for i in range(ndim):
        res_arr = utils.create_output_descriptor(result_shape, kernel_data.return_type, None)

        q = <c_dpctl.SyclQueue> res_arr.get_array().sycl_queue
        q_ref = q.get_queue_ref()

        event_ref = func(q_ref, res_arr.get_data(), res_size, NULL)

        with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
        c_dpctl.DPCTLEvent_Delete(event_ref)

        res_list.append(res_arr.get_pyobj())

    return tuple(res_list)


cpdef utils.dpnp_descriptor dpnp_diagonal(dpnp_descriptor x1, offset=0):
    cdef shape_type_c x1_shape = x1.shape

    n = min(x1.shape[0], x1.shape[1])
    res_shape = [None] * (x1.ndim - 1)

    if x1.ndim > 2:
        for i in range(x1.ndim - 2):
            res_shape[i] = x1.shape[i + 2]

    if (n + offset) > x1.shape[1]:
        res_shape[-1] = x1.shape[1] - offset
    elif (n + offset) > x1.shape[0]:
        res_shape[-1] = x1.shape[0]
    else:
        res_shape[-1] = n + offset

    cdef shape_type_c result_shape = res_shape
    res_ndim = len(res_shape)

    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(x1.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_DIAGONAL_EXT, param1_type, param1_type)

    x1_obj = x1.get_array()

    cdef utils.dpnp_descriptor result = utils.create_output_descriptor(result_shape,
                                                                       kernel_data.return_type,
                                                                       None,
                                                                       device=x1_obj.sycl_device,
                                                                       usm_type=x1_obj.usm_type,
                                                                       sycl_queue=x1_obj.sycl_queue)

    result_sycl_queue = result.get_array().sycl_queue

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> result_sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef custom_indexing_2in_1out_func_ptr_t_ func = <custom_indexing_2in_1out_func_ptr_t_ > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    x1.get_data(),
                                                    x1.size,
                                                    result.get_data(),
                                                    offset,
                                                    x1_shape.data(),
                                                    result_shape.data(),
                                                    res_ndim,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)

    return result


cpdef dpnp_fill_diagonal(dpnp_descriptor x1, val):
    x1_obj = x1.get_array()

    cdef shape_type_c x1_shape = x1.shape
    cdef utils.dpnp_descriptor val_arr = utils_py.create_output_descriptor_py((1,),
                                                                              x1.dtype,
                                                                              None,
                                                                              device=x1_obj.sycl_device,
                                                                              usm_type=x1_obj.usm_type,
                                                                              sycl_queue=x1_obj.sycl_queue)

    val_arr.get_pyobj()[0] = val

    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(x1.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_FILL_DIAGONAL_EXT, param1_type, param1_type)

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> x1_obj.sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef custom_indexing_2in_func_ptr_t func = <custom_indexing_2in_func_ptr_t > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    x1.get_data(),
                                                    val_arr.get_data(),
                                                    x1_shape.data(),
                                                    x1.ndim,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)


cpdef object dpnp_indices(dimensions):
    len_dimensions = len(dimensions)
    res_shape = []
    res_shape.append(len_dimensions)
    for i in range(len_dimensions):
        res_shape.append(dimensions[i])

    result = []
    if len_dimensions == 1:
        res = []
        for i in range(dimensions[0]):
            res.append(i)
        result.append(res)
    else:
        res1 = []
        for i in range(dimensions[0]):
            res = []
            for j in range(dimensions[1]):
                res.append(i)
            res1.append(res)
        result.append(res1)

        res2 = []
        for i in range(dimensions[0]):
            res = []
            for j in range(dimensions[1]):
                res.append(j)
            res2.append(res)
        result.append(res2)

    dpnp_result = dpnp.array(result)
    return dpnp_result


cpdef dpnp_put(dpnp_descriptor x1, object ind, v):
    ind_is_list = isinstance(ind, list)

    x1_obj = x1.get_array()

    if dpnp.isscalar(ind):
        ind_size = 1
    else:
        ind_size = len(ind)
    cdef utils.dpnp_descriptor ind_array = utils_py.create_output_descriptor_py((ind_size,),
                                                                                 dpnp.int64,
                                                                                 None,
                                                                                 device=x1_obj.sycl_device,
                                                                                 usm_type=x1_obj.usm_type,
                                                                                 sycl_queue=x1_obj.sycl_queue)
    if dpnp.isscalar(ind):
        ind_array.get_pyobj()[0] = ind
    else:
        for i in range(ind_size):
            ind_array.get_pyobj()[i] = ind[i]

    if dpnp.isscalar(v):
        v_size = 1
    else:
        v_size = len(v)
    cdef utils.dpnp_descriptor v_array = utils_py.create_output_descriptor_py((v_size,),
                                                                               x1.dtype,
                                                                               None,
                                                                               device=x1_obj.sycl_device,
                                                                               usm_type=x1_obj.usm_type,
                                                                               sycl_queue=x1_obj.sycl_queue)
    if dpnp.isscalar(v):
        v_array.get_pyobj()[0] = v
    else:
        for i in range(v_size):
            v_array.get_pyobj()[i] = v[i]

    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(x1.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_PUT_EXT, param1_type, param1_type)

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> x1_obj.sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef custom_indexing_6in_func_ptr_t func = <custom_indexing_6in_func_ptr_t > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    x1.get_data(),
                                                    ind_array.get_data(),
                                                    v_array.get_data(),
                                                    x1.size,
                                                    ind_array.size,
                                                    v_array.size,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)


cpdef dpnp_put_along_axis(dpnp_descriptor arr, dpnp_descriptor indices, dpnp_descriptor values, int axis):
    cdef shape_type_c arr_shape = arr.shape
    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(arr.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_PUT_ALONG_AXIS_EXT, param1_type, param1_type)

    utils.get_common_usm_allocation(arr, indices)  # check USM allocation is common
    _, _, result_sycl_queue = utils.get_common_usm_allocation(arr, values)

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> result_sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef custom_indexing_3in_with_axis_func_ptr_t func = <custom_indexing_3in_with_axis_func_ptr_t > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    arr.get_data(),
                                                    indices.get_data(),
                                                    values.get_data(),
                                                    axis,
                                                    arr_shape.data(),
                                                    arr.ndim,
                                                    indices.size,
                                                    values.size,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)


cpdef dpnp_putmask(utils.dpnp_descriptor arr, utils.dpnp_descriptor mask, utils.dpnp_descriptor values):
    cdef int values_size = values.size

    mask_flatiter = mask.get_pyobj().flat
    arr_flatiter = arr.get_pyobj().flat
    values_flatiter = values.get_pyobj().flat

    for i in range(arr.size):
        if mask_flatiter[i]:
            arr_flatiter[i] = values_flatiter[i % values_size]


cpdef utils.dpnp_descriptor dpnp_select(list condlist, list choicelist, default):
    cdef size_t size_ = condlist[0].size
    cdef utils.dpnp_descriptor res_array = utils_py.create_output_descriptor_py(condlist[0].shape, choicelist[0].dtype, None)

    pass_val = {a: default for a in range(size_)}
    for i in range(len(condlist)):
        for j in range(size_):
            if (condlist[i])[j]:
                res_array.get_pyobj()[j] = (choicelist[i])[j]
                pass_val.pop(j)

    for ind, val in pass_val.items():
        res_array.get_pyobj()[ind] = val

    return res_array


cpdef utils.dpnp_descriptor dpnp_take(utils.dpnp_descriptor x1, utils.dpnp_descriptor indices):
    cdef DPNPFuncType param1_type = dpnp_dtype_to_DPNPFuncType(x1.dtype)
    cdef DPNPFuncType param2_type = dpnp_dtype_to_DPNPFuncType(indices.dtype)

    cdef DPNPFuncData kernel_data = get_dpnp_function_ptr(DPNP_FN_TAKE_EXT, param1_type, param2_type)

    x1_obj = x1.get_array()

    cdef utils.dpnp_descriptor result = utils.create_output_descriptor(indices.shape,
                                                                       kernel_data.return_type,
                                                                       None,
                                                                       device=x1_obj.sycl_device,
                                                                       usm_type=x1_obj.usm_type,
                                                                       sycl_queue=x1_obj.sycl_queue)

    result_sycl_queue = result.get_array().sycl_queue

    cdef c_dpctl.SyclQueue q = <c_dpctl.SyclQueue> result_sycl_queue
    cdef c_dpctl.DPCTLSyclQueueRef q_ref = q.get_queue_ref()

    cdef custom_indexing_2in_1out_func_ptr_t func = <custom_indexing_2in_1out_func_ptr_t > kernel_data.ptr

    cdef c_dpctl.DPCTLSyclEventRef event_ref = func(q_ref,
                                                    x1.get_data(),
                                                    x1.size,
                                                    indices.get_data(),
                                                    result.get_data(),
                                                    indices.size,
                                                    NULL)  # dep_events_ref

    with nogil: c_dpctl.DPCTLEvent_WaitAndThrow(event_ref)
    c_dpctl.DPCTLEvent_Delete(event_ref)

    return result


cpdef object dpnp_take_along_axis(object arr, object indices, int axis):
    cdef long size_arr = arr.size
    cdef shape_type_c shape_arr = arr.shape
    cdef shape_type_c output_shape
    cdef long size_indices = indices.size
    res_type = arr.dtype

    if axis != arr.ndim - 1:
        res_shape_list = list(shape_arr)
        res_shape_list[axis] = 1
        res_shape = tuple(res_shape_list)

        output_shape = (0,) * (len(shape_arr) - 1)
        ind = 0
        for id, shape_axis in enumerate(shape_arr):
            if id != axis:
                output_shape[ind] = shape_axis
                ind += 1

        prod = 1
        for i in range(len(output_shape)):
            if output_shape[i] != 0:
                prod *= output_shape[i]

        result_array = dpnp.empty((prod, ), dtype=res_type)
        ind_array = [None] * prod
        arr_shape_offsets = [None] * len(shape_arr)
        acc = 1

        for i in range(len(shape_arr)):
            ind = len(shape_arr) - 1 - i
            arr_shape_offsets[ind] = acc
            acc *= shape_arr[ind]

        output_shape_offsets = [None] * len(shape_arr)
        acc = 1

        for i in range(len(output_shape)):
            ind = len(output_shape) - 1 - i
            output_shape_offsets[ind] = acc
            acc *= output_shape[ind]
            result_offsets = arr_shape_offsets[:]  # need copy. not a reference
        result_offsets[axis] = 0

        for source_idx in range(size_arr):

            # reconstruct x,y,z from linear source_idx
            xyz = []
            remainder = source_idx
            for i in arr_shape_offsets:
                quotient, remainder = divmod(remainder, i)
                xyz.append(quotient)

            # extract result axis
            result_axis = []
            for idx, offset in enumerate(xyz):
                if idx != axis:
                    result_axis.append(offset)

            # Construct result offset
            result_offset = 0
            for i, result_axis_val in enumerate(result_axis):
                result_offset += (output_shape_offsets[i] * result_axis_val)

            arr_elem = arr.item(source_idx)
            if ind_array[result_offset] is None:
                ind_array[result_offset] = 0
            else:
                ind_array[result_offset] += 1

            if ind_array[result_offset] % size_indices == indices.item(result_offset % size_indices):
                result_array[result_offset] = arr_elem

        dpnp_result_array = dpnp.reshape(result_array, res_shape)
        return dpnp_result_array

    else:
        result_array = utils_py.create_output_descriptor_py(shape_arr, res_type, None).get_pyobj()

        result_array_flatiter = result_array.flat

        for i in range(size_arr):
            ind = size_indices * (i // size_indices) + indices.item(i % size_indices)
            result_array_flatiter[i] = arr.item(ind)

        return result_array


cpdef tuple dpnp_tril_indices(n, k=0, m=None):
    array1 = []
    array2 = []
    if m is None:
        for i in range(n):
            for j in range(i + 1 + k):
                if j >= n:
                    continue
                else:
                    array1.append(i)
                    array2.append(j)
    else:
        for i in range(n):
            for j in range(i + 1 + k):
                if j < m:
                    array1.append(i)
                    array2.append(j)

    array1 = dpnp.array(array1, dtype=dpnp.int64)
    array2 = dpnp.array(array2, dtype=dpnp.int64)
    return (array1, array2)


cpdef tuple dpnp_tril_indices_from(dpnp_descriptor arr, k=0):
    m = arr.shape[0]
    n = arr.shape[1]
    array1 = []
    array2 = []
    if m is None:
        for i in range(n):
            for j in range(i + 1 + k):
                if j >= n:
                    continue
                else:
                    array1.append(i)
                    array2.append(j)
    else:
        for i in range(n):
            for j in range(i + 1 + k):
                if j < m:
                    array1.append(i)
                    array2.append(j)

    array1 = dpnp.array(array1, dtype=dpnp.int64)
    array2 = dpnp.array(array2, dtype=dpnp.int64)
    return (array1, array2)


cpdef tuple dpnp_triu_indices(n, k=0, m=None):
    array1 = []
    array2 = []
    if m is None:
        for i in range(n):
            for j in range(i + k, n):
                array1.append(i)
                array2.append(j)
    else:
        for i in range(n):
            for j in range(i + k, m):
                array1.append(i)
                array2.append(j)

    array1 = dpnp.array(array1, dtype=dpnp.int64)
    array2 = dpnp.array(array2, dtype=dpnp.int64)
    return (array1, array2)


cpdef tuple dpnp_triu_indices_from(dpnp_descriptor arr, k=0):
    m = arr.shape[0]
    n = arr.shape[1]
    array1 = []
    array2 = []
    if m is None:
        for i in range(n):
            for j in range(i + k, n):
                array1.append(i)
                array2.append(j)
    else:
        for i in range(n):
            for j in range(i + k, m):
                array1.append(i)
                array2.append(j)

    array1 = dpnp.array(array1, dtype=dpnp.int64)
    array2 = dpnp.array(array2, dtype=dpnp.int64)
    return (array1, array2)
