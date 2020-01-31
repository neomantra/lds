//
// lds - LuaJIT Data Structures
//
// Copyright (c) 2012-2020 Evan Wies.  All rights reserved.
// MIT License, see the COPYRIGHT file.
//
// Inserts a number of random points
// into random indexes in a boost::unordered_map.
//
// Build with:
//   g++ -o perf_unordered_map_insert -O3 tests/perf_unordered_map_insert.cpp
//
// I use boost in macports, so I needed to add:
//    -I/opt/local/include

#include <cstdlib>
#include <cstdio>
#include <sys/time.h>
#include <vector>
#include <boost/lexical_cast.hpp>
#include <boost/unordered_set.hpp>
#include <boost/unordered_map.hpp>


int NUMBER_OF_INSERTS = 1e6;


struct Point4 {
    Point4( double _x, double _y, double _z, double _w )
        : x(_x), y(_y), z(_z), w(_w)
    {}

    static Point4 random() {
        return Point4( std::rand(), std::rand(), std::rand(), std::rand() );
    }

    double x, y, z, w;
};


void benchmark( const std::string& name, void(*fn)() )
{
    timeval start_tv, end_tv;
    gettimeofday( &start_tv, NULL );

    fn();

    gettimeofday( &end_tv, NULL );

    std::printf( "%s run:%0.03f  num:%d\n",
        name.c_str(),
        end_tv.tv_sec - start_tv.tv_sec + 1e-6 * (end_tv.tv_usec - start_tv.tv_usec),
        NUMBER_OF_INSERTS );
}


void test_PointVec_insert()
{
    typedef std::vector<Point4> PointVec;
    PointVec point_vec;

    for( int i = 0; i < NUMBER_OF_INSERTS; ++i )
        point_vec.push_back( Point4::random() );    
}


void test_DoubleSet_insert()
{
    typedef boost::unordered_set<double> DoubleSet;
    DoubleSet double_set;

    for( int i = 0; i < NUMBER_OF_INSERTS; ++i )
        double_set.insert( std::rand() );    
}


void test_PointMap_insert()
{
    typedef boost::unordered_map<double, Point4> PointMap;
    PointMap point_map;

    for( int i = 0; i < NUMBER_OF_INSERTS; ++i )
        point_map.insert( std::make_pair(std::rand(), Point4::random()) );    
}


int main( int argc, const char* argv[] )
{
    try {       
        if( argc != 1 && argc != 2 )
            throw std::invalid_argument("usage:  perf_unordered_map_insert  <num_inserts>");

        if( argc == 2 )
            NUMBER_OF_INSERTS = boost::lexical_cast<int>(argv[1]);
    } catch( const std::exception& e ) {
        std::cerr << e.what() << std::endl;
        return -1;
    }

    benchmark( "insert into vector<Point4>", test_PointVec_insert );
    benchmark( "insert into unordered_set<double>", test_DoubleSet_insert );
    benchmark( "insert into unordered_map<double, Point4>",test_PointMap_insert );

    return 0;
}
