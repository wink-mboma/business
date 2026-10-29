import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Cached product/profile image with a soft shimmer placeholder and graceful fallback.
class StoreNetworkImage extends StatelessWidget {
  const StoreNetworkImage({super.key, required this.url, this.fit = BoxFit.cover, this.width, this.height, this.borderRadius, this.fallbackIcon = Icons.image_outlined});
  final String? url; final BoxFit fit; final double? width, height; final BorderRadius? borderRadius; final IconData fallbackIcon;
  @override Widget build(BuildContext context) {
    final value=(url??'').trim();
    final child=value.isEmpty ? _fallback() : CachedNetworkImage(
      imageUrl:value, fit:fit, width:width, height:height,
      placeholder:(context,_)=>Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:const Color(0xFFF7F7F7),child:Container(width:width,height:height,color:Colors.white)),
      errorWidget:(context,_,__)=>_fallback(),
    );
    return ClipRRect(borderRadius:borderRadius??BorderRadius.zero,child:child);
  }
  Widget _fallback()=>Container(width:width,height:height,color:const Color(0xFFF1F1F1),alignment:Alignment.center,child:Icon(fallbackIcon,color:const Color(0xFF9A9A9A),size:28));
}
