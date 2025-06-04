


# Console app
#------------------


set(HPC_PG_CONSOLE_APP_TARGET "${_HPC_TARGET_BASE_NAME}_console_app")

set(_HPC_PG_CONSOLE_APP_SOURCE_FILES)
list(APPEND _HPC_PG_CONSOLE_APP_SOURCE_FILES
        console_app/main.cpp
)

set(_HPC_PG_CONSOLE_APP_PRIVATE_DEPS)
list(APPEND _HPC_PG_CONSOLE_APP_PRIVATE_DEPS)

#TODO: Add copy dll files script if there is
# any dependent shared lib
add_executable(${HPC_PG_CONSOLE_APP_TARGET} "")
target_sources(${HPC_PG_CONSOLE_APP_TARGET}
    PRIVATE
        ${_HPC_PG_CONSOLE_APP_SOURCE_FILES}
)

# target_link_libraries(${BELIK_CONSOLE_APP_TARGET}
#     PRIVATE
#         ${_BELIK_CONSOLE_APP_PRIVATE_DEPS}
# )