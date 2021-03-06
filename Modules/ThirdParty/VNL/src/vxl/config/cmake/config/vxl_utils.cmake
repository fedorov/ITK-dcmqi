#
# INSTALL_NOBASE_HEADER_FILES(prefix file file file ...)
# Will create install rules for those files of the list
# which are headers (.h, .hxx or .hxx).
# If .in files are given, the .in extension is removed.
#

macro(INSTALL_NOBASE_HEADER_FILES prefix)
  foreach(file ${ARGN})
    if(${file} MATCHES "\\.(h|hxx|txx)?$")
      string(REGEX REPLACE "\\.in$" "" install_file ${file})
      get_filename_component(dir ${install_file} PATH)
      # message("install_file=${prefix}/${dir}/${install_file}")
      install(FILES ${install_file}
              DESTINATION ${prefix}/${dir}
              PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
              COMPONENT Development )
    endif()
    if(${file} MATCHES "\\.in?$")
      string(REGEX REPLACE "\\.in$" "" install_file ${file})
      if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${install_file})
        # message("install_file=${CMAKE_CURRENT_BINARY_DIR}/${install_file}")
        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${install_file}
                DESTINATION ${prefix}
                COMPONENT Development )
      else()
        message(WARNING "File not found: ${CMAKE_CURRENT_BINARY_DIR}/${install_file}")
      endif()
    endif()
  endforeach()
endmacro()

##
#
# A macro to setup configuration and installation of header files
#
macro(vxl_configure_file infile outfile installprefix)
  configure_file(${infile}  ${outfile}  ESCAPE_QUOTES @ONLY)
  install(FILES ${outfile}
      DESTINATION ${installprefix}
      PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
      COMPONENT Development )
endmacro()

##
#
# A macro to setup configuration and installation of header files
#
macro(vxl_configure_file_copyonly infile outfile installprefix)
  configure_file(${infile}  ${outfile} COPYONLY)
  install(FILES ${outfile}
      DESTINATION ${installprefix}
      PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
      COMPONENT Development )
endmacro()

#
# A macro to configure where libraries are to be installed for
# vxl for adding a library, setting it's properties, and
# setting it's install location
#
#  LIBNAME (required) is the name of the library to create
#  LIBSRC  (required) is a list of sources needed to create the library
#
macro( vxl_add_library )
  unset(lib_srcs)
  unset(_doing)
  foreach(arg ${ARGN})
    ### Parse itk_module named options
    if("${arg}" MATCHES "^LIBNAME$")
      set(_doing "${arg}")
    elseif("${arg}" MATCHES "^LIBSRCS$")
      set(_doing "${arg}")
    ### Parse named option parameters
    elseif("${_doing}" MATCHES "^LIBNAME$")
      set(lib_name "${arg}")
    elseif("${_doing}" MATCHES "^LIBSRCS$")
      list(APPEND lib_srcs "${arg}")
    endif()
  endforeach()

  ## If not source files, then no lib created
  list(LENGTH lib_srcs num_src_files)
  if( ${num_src_files} GREATER 0 )
    add_library(${lib_name} ${lib_srcs} )

    set_property(GLOBAL APPEND PROPERTY VXLTargets_MODULES ${lib_name})
    if(VXL_LIBRARY_PROPERTIES)
       set_target_properties(${lib_name} PROPERTIES ${VXL_LIBRARY_PROPERTIES})
    endif()

    # Installation
    if(NOT VXL_INSTALL_NO_LIBRARIES)
      install(TARGETS ${lib_name}
        EXPORT ${VXL_INSTALL_EXPORT_NAME}
        RUNTIME DESTINATION ${VXL_INSTALL_RUNTIME_DIR} COMPONENT RuntimeLibraries
        LIBRARY DESTINATION ${VXL_INSTALL_LIBRARY_DIR} COMPONENT RuntimeLibraries
        ARCHIVE DESTINATION ${VXL_INSTALL_ARCHIVE_DIR} COMPONENT Development)
    endif()
  endif()
  if(NOT VXL_INSTALL_NO_DEVELOPMENT)
    ## Identify the relative path for installing the header files and txx files
    string(REPLACE ${VXL_ROOT_SOURCE_DIR} "include/vxl" relative_install_path ${CMAKE_CURRENT_SOURCE_DIR})
    # message(STATUS "${CMAKE_CURRENT_SOURCE_DIR}\n${VXL_ROOT_SOURCE_DIR}\n${relative_install_path}")
    ## Added in 2.8.11 http://stackoverflow.com/questions/19460707/how-to-set-include-directories-from-a-cmakelists-txt-file
    if(${CMAKE_VERSION} VERSION_GREATER 2.8.10)
      target_include_directories(${lib_name}
        PUBLIC
          $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
          $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/${relative_install_path}>
      )
    endif()
    INSTALL_NOBASE_HEADER_FILES(${relative_install_path} ${lib_srcs})
  endif()
  unset(lib_srcs)
  unset(_doing)
endmacro()

#---------------------------------------------------------------------
# GENERATE_TEST_DRIVER(<lib> <sources> [<lib1> <lib2> ...])
#
# - lib     : name of library being tested (e.g., vil, vul, etc.)
# - sources : variable containing the list of source files
# - libN    : libraries to link to
#
# If a test needs to be passed some arguments, you can provide them in
# a cmake variable named by the tests filename appended with '_args'
# (e.g., test_arg_args).
#
# Example usage:
#   set(vil_test_sources
#     ...
#     test_stream.cxx
#     ...
#   )
#   set(test_stream_args ${CMAKE_CURRENT_SOURCE_DIR}/file_read_data)
#   GENERATE_TEST_DRIVER(vil vil_test_sources vil vpl vul testlib vcl)
#---------------------------------------------------------------------
macro(GENERATE_TEST_DRIVER LIB SOURCES)
  create_test_sourcelist(test_driver_sources ${LIB}_test_driver.cxx
    ${${SOURCES}}
  )

  add_executable(${LIB}_test_driver ${test_driver_sources})
  # ***** what if ARGN is empty?
  target_link_libraries(${LIB}_test_driver ${ARGN})

  set(tests_to_run ${test_driver_sources})
  list(REMOVE_ITEM tests_to_run ${LIB}_test_driver.cxx)

  foreach(test ${tests_to_run})
    get_filename_component(test_name ${test} NAME_WE)
    add_test( NAME ${LIB}_${test_name}
              COMMAND $<TARGET_FILE:${LIB}_test_driver> ${test_name} ${${test_name}_args}
            )
  endforeach()
endmacro()

#---------------------------------------------------------------------
# GENERATE_TEST_INCLUDE(<lib> <sources> <prefix>)
#
# - lib     : name of library (e.g., vil, vil_io, pbl, etc.)
# - sources : variable containing the list of library sources
# - prefix  : prefix used in the include statement
#
# Example usage:
#   GENERATE_TEST_INCLUDE(vil_io vil_io_sources "vil/io/")
#---------------------------------------------------------------------
macro(GENERATE_TEST_INCLUDE LIB SOURCES PREFIX)
  set(CMAKE_CONFIGURABLE_FILE_CONTENT "/* */\n")
  foreach(FILE ${${SOURCES}})
    get_filename_component(FILE_EXT ${FILE} EXT)
    if(FILE_EXT STREQUAL ".h")
      set(CMAKE_CONFIGURABLE_FILE_CONTENT
          "${CMAKE_CONFIGURABLE_FILE_CONTENT}#include <${PREFIX}${FILE}>\n#include <${PREFIX}${FILE}>\n")
    endif()
  endforeach()

  set(CMAKE_CONFIGURABLE_FILE_CONTENT
      "${CMAKE_CONFIGURABLE_FILE_CONTENT}\n\nint main(){return 0;}\n")

  configure_file("${CMAKE_ROOT}/Modules/CMakeConfigurableFile.in"
                 "${CMAKE_CURRENT_BINARY_DIR}/test_include.cxx"
                 @ONLY)

  add_executable(${LIB}_test_include ${CMAKE_CURRENT_BINARY_DIR}/test_include.cxx)
  target_link_libraries(${LIB}_test_include ${LIB})
endmacro()
