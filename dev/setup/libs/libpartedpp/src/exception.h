#ifndef PED_EXCEPTION_H
#define PED_EXCEPTION_H

#include <iostream>
#include <stdexcept>
#include <string>

namespace Ped {

    class Exception : public std::exception {

        private:
            std::string msg;

        public:
            Exception(std::string &message);

            virtual const char* what() const throw();

            virtual ~Exception() throw();

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
