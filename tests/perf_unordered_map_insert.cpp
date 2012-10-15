// Inserts a number of random points
// into random indexes in a boost::unordered_map.
//
// Build with:
//   g++ -o perf_unordered_map_insert -O3 tests/perf_unordered_map_insert.cpp
//
// I use boost in macports, so I needed to add:
//    -I/opt/local/include

#include <cstdlib>
#include <sys/time.h>
#include <boost/unordered_map.hpp>
#include <boost/lexical_cast.hpp>


struct Point4 {
    Point4( double _x, double _y, double _z, double _w )
        : x(_x), y(_y), z(_z), w(_w)
    {}

    static Point4 random() {
        return Point4( std::rand(), std::rand(), std::rand(), std::rand() );
    }

    double x, y, z, w;
};


int main( int argc, const char* argv[] )
{
    int NUMBER_OF_INSERTS;
    try {       
        if( argc != 1 && argc != 2 )
            throw std::invalid_argument("perf_unordered_map_insert num_inserts");

        if( argc == 1 )
            NUMBER_OF_INSERTS = 1e6;
        else
            NUMBER_OF_INSERTS = boost::lexical_cast<int>(argv[1]);
    } catch( const std::exception& e ) {
        std::cerr << e.what() << std::endl;
        return -1;
    }

    timeval start_tv, end_tv;
    gettimeofday( &start_tv, NULL );
    ////////
    typedef boost::unordered_map<double, Point4> PointMap;
    PointMap point_map;

    for( int i = 0; i < NUMBER_OF_INSERTS; ++i )
        point_map.insert( std::make_pair(std::rand(), Point4::random()) );
    ////////
    gettimeofday( &end_tv, NULL );

    std::printf( "perf_unordered_map_insert... run:%0.03g  num:%d\n",
        end_tv.tv_sec - start_tv.tv_sec + 1e-6 * (end_tv.tv_usec - start_tv.tv_usec),
        NUMBER_OF_INSERTS );
    return 0;
}
