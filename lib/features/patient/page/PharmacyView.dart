import 'package:flutter/material.dart';
import 'package:flutter_diease_app/config/base_config.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class PharmacyView extends StatefulWidget {
  const PharmacyView({super.key});

  @override
  State<PharmacyView> createState() => _PharmacyView();
}
class _PharmacyView extends State<PharmacyView>{
  // 맵에 필요한 변수들 선언
  late List<MapLatLng> mapMarkers;
  late MapTileLayerController mapController;
  late MapLatLng initialLatLng;
  late MapZoomPanBehavior _zoomPanBehavior;

  @override
  void initState(){
    super.initState();
    // 맵 컨트롤러 선언
    mapController = MapTileLayerController();
    // 맵 마커 초기 위치
    mapMarkers = <MapLatLng>[MapLatLng(37.669231, 126.739327)];
    // 맵 초기 위치
    initialLatLng = MapLatLng(37.669231, 126.739327);

    // 맵 zoom, panning 선언
    _zoomPanBehavior = MapZoomPanBehavior(
    zoomLevel: 14.5,
    minZoomLevel: 9,
    maxZoomLevel: 18,
    enablePanning: true,
    enablePinching: true
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 자동 뒤로가기 불가
        title: const Text("근처 약국"),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body :SfMaps( // SfMaps: 플러터 지도 라이브러리
        layers: [ // 필수 파라미터
          MapTileLayer( // 지도 타일 및 여러 속성을 지정하여 지도를 커스터마이징
            urlTemplate: BaseConfig.vWorldUrl, // vWorldUrl을 통해 지도 표출, urlTemplate : 지도 타일의 이미지를 가져오기 위한 URL패턴을 지정하는 속성
            controller: mapController, // mapController: 지도 컨트롤러
            initialMarkersCount: mapMarkers.length, // 지도에 표시될 마커 개수
            initialZoomLevel: 14, // initialZoomLevel: 초기 줌 레벨
            zoomPanBehavior: _zoomPanBehavior, // zoom, panning을 지정해둔 변수
            initialFocalLatLng: initialLatLng, // 지도의 초기 위치 설정
            markerBuilder: (BuildContext context, int index) { // 지도에 표시될 마커 생성
              return MapMarker(
                  longitude: mapMarkers[index].longitude,
                  latitude: mapMarkers[index].latitude,
                  size: Size(30, 30),
                  );
              },
          ),
        ],
      )
      // body: Container(
      //   child : Text("테스트"),
      // )
    );
  }
}
