#ifndef PED_FILESYSTEMTYPE_H
#define PED_FILESYSTEMTYPE_H

#include <stdexcept>
#include <string>
#include "device.h"

namespace Ped {

    class FileSystemType {

        friend class FileSystem;
        friend class Partition;

        private:
        FileSystemType( );
        FileSystemType(const PedFileSystemType *fst);
        FileSystemType(const FileSystemType &fst);
        FileSystemType& operator=(const FileSystemType &fst);

        PedFileSystemType   *fs_type_;

        public:
        // ped_file_system_type_get()
        FileSystemType                                  (std::string &name);
        // destructor
        ~FileSystemType                                 ( );
        //  ped_file_system_type_get_next()
        FileSystemType&          get_next               ( ) throw (std::runtime_error);
        // for accessing the C type in another class
        const PedFileSystemType* get_c_file_system_type ( ) const;
        const std::string&       get_name               ( ) const;

        protected:

    };

};

#endif

