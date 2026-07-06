import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;

Widget posSaleChannelList(
    {required Function(int) onTab, required int selectedIndex}) {
  return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
    int widgetPerLine =
        int.parse((constraints.maxWidth / 200).toStringAsFixed(0));
    return GridView.count(
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: widgetPerLine,
        childAspectRatio: 1.5,
        padding: EdgeInsets.zero,
        children: List.generate(global.posSaleChannelLists.length, (index) {
          return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade200,
                padding: const EdgeInsets.only(
                    top: 20.0, bottom: 20.0, left: 0.0, right: 0.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: () {
                onTab(index);
              },
              child: Center(
                child: Column(
                  children: [
                    Expanded(
                        child: CachedNetworkImage(
                      imageUrl: global.posSaleChannelLists[index].logoUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )),
                    const SizedBox(height: 10),
                    (selectedIndex == index)
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 5),
                              Text(global.posSaleChannelLists[index].name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ],
                          )
                        : Text(global.posSaleChannelLists[index].name,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black)),
                  ],
                ),
              ));
        }));
  });
}
