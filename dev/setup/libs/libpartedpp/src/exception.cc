#include "exception.h"

using namespace Ped;

Exception::Exception(std::string &message)
    : msg(message) {
}

const char* Exception::what() const throw() {
   return (msg.c_str());
}

Exception::~Exception() throw() {
}

/* vim: set tabstop=4 et shiftwidth=4: */
