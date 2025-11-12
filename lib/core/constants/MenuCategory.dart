
// 메뉴 카테고리 아이콘&타이틀 넣는 곳
class MenuCategory {
  final String icon, title;
  final String url;

  const MenuCategory({
    required this.icon,
    required this.title,
    required this.url
  });
}
//테스트용
const List<MenuCategory> menu_categories = [
  MenuCategory(icon: "assets/icons/Pediatrician.svg", title: "환자메인화면", url:"/patientMain"),
  MenuCategory(icon: "assets/icons/Neurosurgeon.svg", title: "의사메인화면", url:"/doctorMain"),
  MenuCategory(icon: "assets/icons/Cardiologist.svg", title: "관리자 메인화면", url:"/adminMain"),
  MenuCategory(icon: "assets/icons/Psychiatrist.svg", title: "내 정보", url:"/myInfo"),
];

const List<MenuCategory> patientMenu = [
  MenuCategory(icon: "assets/icons/Pediatrician.svg", title: "홈", url: "/patientMain"),
  MenuCategory(icon: "assets/icons/Psychiatrist.svg", title: "내 정보", url: "/myInfo"),
];

const List<MenuCategory> doctorMenu = [
  MenuCategory(icon: "assets/icons/Neurosurgeon.svg", title: "진료", url: "/doctorMain"),
  MenuCategory(icon: "assets/icons/Psychiatrist.svg", title: "내 정보", url: "/myInfo"),
];

const List<MenuCategory> adminMenu = [
  MenuCategory(icon: "assets/icons/Cardiologist.svg", title: "관리", url: "/adminMain"),
  MenuCategory(icon: "assets/icons/Cardiologist.svg", title: "회원 승인", url: "/approval"),
  MenuCategory(icon: "assets/icons/Cardiologist.svg", title: "전체 회원관리", url: "/allUser"),
  MenuCategory(icon: "assets/icons/Psychiatrist.svg", title: "내 정보", url: "/myInfo"),
];