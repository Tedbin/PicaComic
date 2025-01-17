import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/models/local_favorites.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/pic_views/comments_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/base.dart';
import '../main_page.dart';
import '../widgets/select_download_eps.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class PicacgComicPage extends ComicPage<ComicItem> {
  final ComicItemBrief comic;
  const PicacgComicPage(this.comic, {super.key});

  @override
  Row get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text(data!.likes.toString()),
              avatar: Icon(
                  (data!.isLiked) ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                network.likeOrUnlikeComic(comic.id);
                data!.isLiked = !data!.isLiked;
                update();
              },
            ),
          ),
          Expanded(
            child: ActionChip(
              label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
              avatar: !favorite ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_add),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: appdata.token != "",
                needLoadFolderData: false,
                folders: const {"Picacg": "Picacg"},
                initialFolder: data!.isFavourite?null:"Picacg",
                favoriteOnPlatform: data!.isFavourite,
                target: comic.id,
                setFavorite: (b){
                  if(favorite != b){
                    favorite = b;
                    update();
                  }
                },
                cancelPlatformFavorite: (){
                  network.favouriteOrUnfavouriteComic(comic.id);
                  data!.isFavourite = false;
                  update();
                },
                selectFolderCallback: (name, p){
                  if(p == 0){
                    network.favouriteOrUnfavouriteComic(comic.id);
                    data!.isFavourite = true;
                    update();
                  }else{
                    showMessage(Get.context, "已添加至收藏夹:".tl + name);
                    LocalFavoritesManager().addComic(
                        name, FavoriteItem.fromPicacg(comic));
                  }
                },
              )),
            ),
          ),
          Expanded(
            child: ActionChip(
              label: Text(data!.comments.toString()),
              avatar: const Icon(Icons.comment_outlined),
              onPressed: () {
                showComments(Get.context!, comic.id);
              },
            ),
          ),
        ],
      );

  @override
  String get cover => comic.path;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () {
          downloadComic(data!, context, data!.eps);
        },
        child: (downloadManager.downloaded.contains(comic.id))
            ? Text("修改".tl)
            : Text("下载".tl),
      );

  @override
  EpsData? get eps => EpsData(data!.eps, (i) {
        addPicacgHistory(data!);
        Get.to(() =>
            ComicReadingPage.picacg(comic.id, i + 1, data!.eps, comic.title));
      });

  @override
  String? get introduction => data?.description;

  @override
  Future<Res<ComicItem>> loadData() => network.getComicInfo(comic.id);

  @override
  int? get pages => data?.pagesCount;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readPicacgComic(data!, data!.eps),
        child: Text("阅读".tl),
      );

  @override
  SliverGrid recommendationBuilder(data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: data.recommendation.length, (context, i) {
          return PicComicTile(data.recommendation[i]);
        }),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: comicTileMaxWidth,
          childAspectRatio: comicTileAspectRatio,
        ),
      );

  @override
  String get tag => "Picacg Comic Page ${comic.id}";

  @override
  Map<String, List<String>>? get tags => {
        "作者".tl: data!.author.toList(),
        "汉化".tl: data!.chineseTeam.toList(),
        "分类".tl: data!.categories,
        "标签".tl: data!.tags
      };

  @override
  void tapOnTags(String tag) =>
      MainPage.to(() => CategoryComicPage(tag));

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => comic.title;

  @override
  Future<bool> loadFavorite(ComicItem data) async{
    return data.isFavourite || (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  Card? get uploaderInfo => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.inversePrimary,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                flex: 0,
                child: Avatar(
                  size: 50,
                  avatarUrl: data!.creator.avatarUrl,
                  frame: data!.creator.frameUrl,
                  couldBeShown: true,
                  name: data!.creator.name,
                  slogan: data!.creator.slogan,
                  level: data!.creator.level,
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data!.creator.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                          "${data!.time.substring(0, 10)} ${data!.time.substring(11, 19)}更新")
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class ComicPageLogic extends GetxController {
  bool isLoading = true;
  ComicItem? comicItem;
  bool showAppbarTitle = false;
  String? message;
  var tags = <Widget>[];
  var categories = <Widget>[];
  var recommendation = <ComicItemBrief>[];
  var controller = ScrollController();
  var eps = <Widget>[
    ListTile(
      leading: const Icon(Icons.library_books),
      title: Text("章节".tl),
    ),
  ];
  var epsStr = <String>[""];
  void change() {
    isLoading = !isLoading;
    update();
  }
}

void downloadComic(
    ComicItem comic, BuildContext context, List<String> eps) async {
  if (GetPlatform.isWeb) {
    showMessage(context, "Web端不支持下载".tl);
    return;
  }
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
      return;
    }
  }
  var downloaded = <int>[];
  if (DownloadManager().downloaded.contains(comic.id)) {
    var downloadedComic = await DownloadManager().getComicFromId(comic.id);
    downloaded.addAll(downloadedComic.downloadedEps);
  }
  if (UiMode.m1(Get.context!)) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (context) {
          return SelectDownloadChapter(eps, (selectedEps) {
            downloadManager.addPicDownload(comic, selectedEps);
            Get.back();
            showMessage(context, "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        Get.context!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addPicDownload(comic, selectedEps);
          Get.back();
          showMessage(context, "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}