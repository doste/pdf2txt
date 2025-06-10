add_executable(${PROJECT_NAME} pdf2txt.cpp main.cpp func.swift)
# changes namespace of swift functions
set_target_properties(pdf2txt PROPERTIES Swift_MODULE_NAME "SwiftPNGGenerator")
target_compile_options(pdf2txt PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>")
target_compile_options(pdf2txt PRIVATE $<$<COMPILE_LANGUAGE:Swift>:-parse-as-library>)

#_swift_generate_cxx_header(pdf2txt pdf2txt/Interop-swift.h)
_swift_generate_cxx_header(pdf2txt pdf2txt/include/pdf2txt.hpp)



find_package(PkgConfig REQUIRED)

pkg_check_modules(tesseract REQUIRED IMPORTED_TARGET tesseract)
pkg_check_modules(leptonica REQUIRED IMPORTED_TARGET lept)
pkg_check_modules(poppler-cpp REQUIRED IMPORTED_TARGET poppler-cpp)


# Setting OpenCV Installation
find_package(OpenCV REQUIRED)
if (OpenCV_FOUND)
    include_directories(${OpenCV_INCLUDE_DIRS})
endif ()


target_link_libraries(${PROJECT_NAME} PUBLIC
    PkgConfig::leptonica
    PkgConfig::tesseract
    PkgConfig::poppler-cpp
    ${OpenCV_LIBS}
)