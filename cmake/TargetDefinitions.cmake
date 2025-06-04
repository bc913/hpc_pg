# -----------------------------------------------------
# Header only library definitions
# -----------------------------------------------------

# IF PUBLIC_HEADERS_BASE_DIR is not given, "include" is considered as base_dir
function(bc_header_only_library TARGET_NAME)
    # Arg definitions
    set(flags)
    set(args BASE_DIR)
    set(listArgs DEP_TARGETS DEFINES)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    if(NOT arg_BASE_DIR)
        message(FATAL_ERROR "BASE_DIR argument should be provided.")
    endif()

    set(_build_interface_)
    if(BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_BASE_DIR STREQUAL "")
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR})
    else()
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR}/${arg_BASE_DIR})
    endif()

    # Definitions
    add_library(${TARGET_NAME} INTERFACE "")
    target_include_directories(
        ${TARGET_NAME}
        INTERFACE
        $<BUILD_INTERFACE:${_build_interface_}> # or ${PROJECT_SOURCE_DIR}/include
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> # or include
    )

    if(arg_DEFINES AND NOT DEFINES IN_LIST arg_KEYWORDS_MISSING_VALUES)
        target_compile_definitions( ${TARGET_NAME} INTERFACE ${arg_DEFINES} )
    endif()

    if(arg_DEP_TARGETS AND NOT DEP_TARGETS IN_LIST arg_KEYWORDS_MISSING_VALUES)
        target_link_libraries(${TARGET_NAME} INTERFACE ${arg_DEP_TARGETS})
    endif()
endfunction()

# Convenience function to define header only targets using file_set
# Pass PUBLIC_HEADERS by ignoring the base dir in the path
# The BASE_DIR will be prepended internally
function(bc_header_only_library_file_set TARGET_NAME)
    # Arg definitions
    set(flags)
    set(args BASE_DIR FILE_SET_NAME)
    set(listArgs PUBLIC_HEADERS DEP_TARGETS DEFINES)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    ## Public_headers must be a list of values
    if (NOT arg_PUBLIC_HEADERS)
        message(FATAL_ERROR "PUBLIC_HEADERS argument should be defined.")
    endif()
    if (PUBLIC_HEADERS IN_LIST arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "PUBLIC_HEADERS argument should have a value.")
    endif()
    ## FILE_SET_NAME
    ## If no value is given use the default value
    set(_file_set_name_)
    if(NOT arg_FILE_SET_NAME OR FILE_SET_NAME IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_FILE_SET_NAME STREQUAL "")
        set(_file_set_name_ ${TARGET_NAME}_header_files) # default value
    else()
        set(_file_set_name_ ${arg_FILE_SET_NAME})
    endif()

    # Definitions
    add_library(${TARGET_NAME} INTERFACE "")

    if(arg_BASE_DIR AND 
        NOT BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES AND 
        NOT ${arg_BASE_DIR} STREQUAL "")
        # Prepend base_dir to existing public header paths otherwise it will fail
        set(_mod_public_headers)
        foreach(public_header ${arg_PUBLIC_HEADERS})
            list(APPEND _mod_public_headers ${arg_BASE_DIR}/${public_header})
        endforeach()        

        target_sources(${TARGET_NAME} 
            INTERFACE
                FILE_SET ${_file_set_name_}
                TYPE HEADERS
                BASE_DIRS ${arg_BASE_DIR}
                FILES ${_mod_public_headers}
        )
    else()
        # Public header files should be resided in CMAKE_CURRENT_SOURCE_DIR
        target_sources(${TARGET_NAME} 
            INTERFACE
                FILE_SET ${_file_set_name_}
                TYPE HEADERS
                FILES ${arg_PUBLIC_HEADERS}
        )
    endif()

    if(arg_DEFINES AND NOT DEFINES IN_LIST arg_KEYWORDS_MISSING_VALUES)
        target_compile_definitions( ${TARGET_NAME} INTERFACE ${arg_DEFINES} )
    endif()

    if(arg_DEP_TARGETS AND NOT DEP_TARGETS IN_LIST arg_KEYWORDS_MISSING_VALUES)
        target_link_libraries( ${TARGET_NAME} INTERFACE ${arg_DEP_TARGETS} )
    endif()

endfunction()

function(bc_install_header_only_library TARGET_NAME)
    # Arg definitions
    set(flags USE_FILE_SET)
    set(args FILE_SET_NAME BASE_DIR)
    set(listArgs)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    if( NOT arg_USE_FILE_SET AND NOT arg_BASE_DIR)
        message(FATAL_ERROR "BASE_DIR should be defined if USE_FILE_SET is disabled.")
    endif()

    # TODO: Refactor for MacOsX whether the target property FRAMEWORK is set
    # Generator expressions does not work for install command args
    include(GNUInstallDirs)
    if(arg_USE_FILE_SET)

        # Define FILE_SET
        set(_file_set_name_)
        if(NOT arg_FILE_SET_NAME OR FILE_SET_NAME IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_FILE_SET_NAME STREQUAL "")
            set(_file_set_name_ ${TARGET_NAME}_header_files) # default value
        else()
            set(_file_set_name_ ${arg_FILE_SET_NAME})
        endif()

        # install
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            FILE_SET ${_file_set_name_} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
    else()
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
        )
        if(BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_BASE_DIR STREQUAL "")
            install( DIRECTORY . DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        else()
            # Assumption: You expose public headers under base_dir. Relative paths are conserved.
            install( DIRECTORY ${arg_BASE_DIR}/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        endif()
        
    endif()
endfunction()

# -----------------------------------------------------
# Static library definitions
# -----------------------------------------------------
function(bc_static_library TARGET_NAME)
    # Arg definitions
    set(flags)
    set(args PUBLIC_HEADERS_BASE_DIR)
    set(listArgs SOURCES PUBLIC_DEP_TARGETS PRIVATE_DEP_TARGETS PUBLIC_DEFINES PRIVATE_DEFINES)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    ## Sources
    if (NOT arg_SOURCES)
        message(FATAL_ERROR "[bc_static_library]: SOURCES is a required argument")
    endif()
    if (SOURCES IN_LIST arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "[bc_static_library]: SOURCES requires at least one value")
    endif()
    ## public headers base dir
    if(NOT arg_PUBLIC_HEADERS_BASE_DIR)
        message(FATAL_ERROR "PUBLIC_HEADERS_BASE_DIR argument should be provided.")
    endif()

    set(_build_interface_)
    if(PUBLIC_HEADERS_BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_PUBLIC_HEADERS_BASE_DIR STREQUAL "")
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR})
    else()
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR}/${arg_PUBLIC_HEADERS_BASE_DIR})
    endif()

    # Definitions
    add_library(${TARGET_NAME} STATIC "")
    target_sources(${TARGET_NAME} PRIVATE ${arg_SOURCES})
    target_include_directories(
        ${TARGET_NAME}
        PUBLIC
        $<BUILD_INTERFACE:${_build_interface_}> # or ${PROJECT_SOURCE_DIR}/include
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> # or include
    )

    # Dependencies are optional
    target_link_libraries(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEP_TARGETS>>>:${arg_PRIVATE_DEP_TARGETS}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEP_TARGETS>>>:${arg_PUBLIC_DEP_TARGETS}>"
    )
    # Compile_time Macro definitions
    target_compile_definitions(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEFINES>>>:${arg_PRIVATE_DEFINES}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEFINES>>>:${arg_PUBLIC_DEFINES}>"
    )

endfunction()

function(bc_static_library_file_set TARGET_NAME)
    # Arg definitions
    set(flags)
    set(args BASE_DIR FILE_SET_NAME)
    set(listArgs PUBLIC_HEADERS SOURCES PUBLIC_DEP_TARGETS PRIVATE_DEP_TARGETS PUBLIC_DEFINES PRIVATE_DEFINES)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    ## Sources
    if (NOT arg_SOURCES)
        message(FATAL_ERROR "[bc_static_library]: SOURCES is a required argument")
    endif()
    if (SOURCES IN_LIST arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "[bc_static_library]: SOURCES requires at least one value")
    endif()

    ## Public_headers must be a list of values
    if (NOT arg_PUBLIC_HEADERS)
        message(FATAL_ERROR "PUBLIC_HEADERS argument should be defined.")
    endif()
    if (PUBLIC_HEADERS IN_LIST arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "PUBLIC_HEADERS argument should have a value.")
    endif()

    ## FILE_SET_NAME
    ## If no value is given use the default value
    set(_file_set_name_)
    if(NOT arg_FILE_SET_NAME OR FILE_SET_NAME IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_FILE_SET_NAME STREQUAL "")
        set(_file_set_name_ ${TARGET_NAME}_header_files) # default value
    else()
        set(_file_set_name_ ${arg_FILE_SET_NAME})
    endif()

    # Definitions
    add_library(${TARGET_NAME} STATIC "")

    if(arg_BASE_DIR AND 
        NOT BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES AND 
        NOT ${arg_BASE_DIR} STREQUAL "")
        
        # Prepend base_dir to existing public header paths otherwise it will fail
        set(_mod_public_headers)
        foreach(public_header ${arg_PUBLIC_HEADERS})
            list(APPEND _mod_public_headers ${arg_BASE_DIR}/${public_header})
        endforeach()        

        target_sources(${TARGET_NAME}
            PRIVATE 
                ${arg_SOURCES}
            PUBLIC
                FILE_SET ${_file_set_name_}
                TYPE HEADERS
                BASE_DIRS ${arg_BASE_DIR}
                FILES ${_mod_public_headers}
        )
    else()
        # Public header files should be resided in CMAKE_CURRENT_SOURCE_DIR
        target_sources(${TARGET_NAME} 
            PRIVATE 
                ${arg_SOURCES}
            PUBLIC
                FILE_SET ${_file_set_name_}
                TYPE HEADERS
                FILES ${arg_PUBLIC_HEADERS}
        )
    endif()


    # Dependencies are optional
    target_link_libraries(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEP_TARGETS>>>:${arg_PRIVATE_DEP_TARGETS}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEP_TARGETS>>>:${arg_PUBLIC_DEP_TARGETS}>"
    )
    # Compile_time Macro definitions, optional too.
    target_compile_definitions(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEFINES>>>:${arg_PRIVATE_DEFINES}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEFINES>>>:${arg_PUBLIC_DEFINES}>"
    )

endfunction()

# If EXPOSE_HEADERS AND USE_FILE_set are enabled, PUBLIC_HEADER_FILE_SET should be provided
# If BASE_DIR is not given, "include" will be used as default.
# BASE_DIR is only be used when EXPOSE_HEADERS is ON and USE_FILE_SET is OFF.
function(bc_install_static_library TARGET_NAME)
    # Arg definitions
    set(flags USE_FILE_SET)
    set(args FILE_SET_NAME BASE_DIR)
    set(listArgs)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    if( NOT arg_USE_FILE_SET AND NOT arg_BASE_DIR)
        message(FATAL_ERROR "BASE_DIR should be defined if USE_FILE_SET is disabled.")
    endif()

    # TODO: Refactor for MacOsX whether the target property FRAMEWORK is set
    # Generator expressions does not work for install command args
    include(GNUInstallDirs)
    if(arg_USE_FILE_SET)
        # Define FILE_SET
        set(_file_set_name_)
        if(NOT arg_FILE_SET_NAME OR FILE_SET_NAME IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_FILE_SET_NAME STREQUAL "")
            set(_file_set_name_ ${TARGET_NAME}_header_files) # default value
        else()
            set(_file_set_name_ ${arg_FILE_SET_NAME})
        endif()
        # install
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            FILE_SET ${_file_set_name_} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )        
    else()
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )

        if(BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_BASE_DIR STREQUAL "")
            install( DIRECTORY . DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        else()
            # Assumption: You expose public headers under base_dir. Relative paths are conserved.
            install( DIRECTORY ${arg_BASE_DIR}/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        endif()
    endif()

endfunction()

# -----------------------------------------------------
# Dynamic library definitions
# -----------------------------------------------------
function(bc_shared_library TARGET_NAME)
    # Arg definitions
    set(flags)
    set(args PUBLIC_HEADERS_BASE_DIR)
    set(listArgs SOURCES PUBLIC_DEP_TARGETS PRIVATE_DEP_TARGETS PUBLIC_DEFINES PRIVATE_DEFINES)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    ## Sources
    if (NOT arg_SOURCES)
        message(FATAL_ERROR "[bc_shared_library]: SOURCES is a required argument")
    endif()
    if (SOURCES IN_LIST arg_KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "[bc_shared_library]: SOURCES requires at least one value")
    endif()
    ## public headers base dir
    if(NOT arg_PUBLIC_HEADERS_BASE_DIR)
        message(FATAL_ERROR "PUBLIC_HEADERS_BASE_DIR argument should be provided.")
    endif()

    set(_build_interface_)
    if(PUBLIC_HEADERS_BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_PUBLIC_HEADERS_BASE_DIR STREQUAL "")
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR})
    else()
        set(_build_interface_ ${CMAKE_CURRENT_SOURCE_DIR}/${arg_PUBLIC_HEADERS_BASE_DIR})
    endif()

    # Definitions
    add_library(${TARGET_NAME} SHARED "")
    target_sources(${TARGET_NAME} PRIVATE ${arg_SOURCES})
    target_include_directories(
        ${TARGET_NAME}
        PUBLIC
        $<BUILD_INTERFACE:${_build_interface_}> # or ${PROJECT_SOURCE_DIR}/include
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> # or include
    )

    # Dependencies are optional
    target_link_libraries(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEP_TARGETS>>>:${arg_PRIVATE_DEP_TARGETS}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEP_TARGETS>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEP_TARGETS>>>:${arg_PUBLIC_DEP_TARGETS}>"
    )
    # Compile_time Macro definitions
    target_compile_definitions(${TARGET_NAME}
            PRIVATE 
                "$<$<AND:$<BOOL:arg_PRIVATE_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PRIVATE_DEFINES>>>:${arg_PRIVATE_DEFINES}>"
            PUBLIC
                "$<$<AND:$<BOOL:arg_PUBLIC_DEFINES>,$<NOT:$<IN_LIST:arg_KEYWORDS_MISSING_VALUES,PUBLIC_DEFINES>>>:${arg_PUBLIC_DEFINES}>"
    )

endfunction()


# If EXPOSE_HEADERS AND USE_FILE_set are enabled, PUBLIC_HEADER_FILE_SET should be provided
# If BASE_DIR is not given, "include" will be used as default.
# BASE_DIR is only be used when EXPOSE_HEADERS is ON and USE_FILE_SET is OFF.
function(bc_install_shared_library TARGET_NAME)
    # Arg definitions
    set(flags USE_FILE_SET)
    set(args FILE_SET_NAME BASE_DIR)
    set(listArgs)
    cmake_parse_arguments(arg "${flags}" "${args}" "${listArgs}" ${ARGN})

    # Checks
    if( NOT arg_USE_FILE_SET AND NOT arg_BASE_DIR)
        message(FATAL_ERROR "BASE_DIR should be defined if USE_FILE_SET is disabled.")
    endif()

    # TODO: Refactor for MacOsX whether the target property FRAMEWORK is set
    # Generator expressions does not work for install command args
    include(GNUInstallDirs)
    if(arg_USE_FILE_SET)
        # Define FILE_SET
        set(_file_set_name_)
        if(NOT arg_FILE_SET_NAME OR FILE_SET_NAME IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_FILE_SET_NAME STREQUAL "")
            set(_file_set_name_ ${TARGET_NAME}_header_files) # default value
        else()
            set(_file_set_name_ ${arg_FILE_SET_NAME})
        endif()
        # install
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            FILE_SET ${_file_set_name_} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )        
    else()
        install(
            TARGETS ${TARGET_NAME}
            EXPORT ${TARGET_NAME}Targets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        )

        if(BASE_DIR IN_LIST arg_KEYWORDS_MISSING_VALUES OR arg_BASE_DIR STREQUAL "")
            install( DIRECTORY . DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        else()
            # Assumption: You expose public headers under base_dir. Relative paths are conserved.
            install( DIRECTORY ${arg_BASE_DIR}/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h*")
        endif()
    endif()

endfunction()
