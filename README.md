# 雨燕
相册相片管理app

不知道大家平时有没有遇到这种问题，就是想给朋友发一张照片的时候，非常的麻烦。不管你是在微信上，还是在qq上，或者直接在iphone的原生照片app里，选一张图片，然后发送（或者分享）。

我们先来看看，这些app中的问题，拿微信举例好了：  
![image](https://github.com/peterchen145/swallow/raw/master/imgs/wechatexsample.png)



我的iphone里有上千张照片，如果想要发一张很早以前的照片，位置可能在相册的中间，那么我们就需要不停的滑啊滑啊滑，这个过程很累。这还是我们知道该图片等位置的时候。如果我们不清楚这张照片在什么位置，那要怎么办呢？只能慢慢地一边滑一遍找，找个几次简直想死。

那么怎么解决这个问题呢？

在电脑上已经解决过这个问题了，就是滚动条。
![image](https://github.com/peterchen145/swallow/raw/master/imgs/scrollbar.png)

有了滚动条，我们只需要按住滚动条，然后拖动，很容易的就可以拖到相册的中间，或者任何你想要的地方。为 了方便，我还在滚动条的顶部和底部各加一个按钮，点击顶部按钮就可以滚动到顶部，点击底部按钮就滚动到底部。

当然，只有滚动条还是不够。

比如我大概知道我想找的照片是在16年7月份的，怎么找呢？

我的方法是把图片按照日期归组，同一天的为一组，然后标明日期，并且各组可以收缩展开，当你需要按时间查找时，可以点击收缩按钮，把图片收起来，然后拖动滚动条，到你想要的日期，再展开那一组照片进行选择，非常方便。
![image](https://github.com/peterchen145/swallow/raw/master/imgs/close.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/opensomeofthem.png)


so far so good.

但是还有一个问题，就是批量选择的问题。

有时候我想选多张图片，尤其是几十张上百张的选，虽然微信qq是支持滑动来进行多选的，但是体验不够好，当我想选的照片还没在屏幕上的时候，就不能选了。

这一点苹果原生的照片app就不错，只要你选择了照片，然后一直按住，把手指移到底部，那么相册会自动上滑，并把出现的照片选中。

雨燕copy了苹果的这个功能。（说copy就copy吧，其实一开始我也想到这样了，就像我们在电脑上，按住鼠标左键然后滚动滚轮，不过后来发现苹果实现了这个功能）。

先看几张图片：

![image](https://github.com/peterchen145/swallow/raw/master/imgs/mutleselection1.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/mutleselection2.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/mutleselection3.png)


也可以看操作需要操作演示视频

http://v.youku.com/v_show/id_XMjYzNDA1NTMwOA==.html?spm=a2hzp.8244740.0.0&from=y1.7-1.2


照片的删除功能，自不必说了

![image](https://github.com/peterchen145/swallow/raw/master/imgs/deleteImg.png)

选择图片的操作基本就这些了。

下面是相册。

不管是微信 qq还是苹果的照片app，基本都是点击一个相册然后进入这个相册，要想切换相册必须先退出当前相册。这在以前，当然是不得以的办法，手机屏幕小嘛。但是随著手机屏幕的增大，我们完全可以摒弃这种麻烦的方式了，直接在左边显示相册，右边显示选中相册的内容，就像电脑上的那样。

雨燕支持基本的相册管理操作：新增，编辑名称，删除。

![image](https://github.com/peterchen145/swallow/raw/master/imgs/addablum.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/editablum.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/deleteAlbum.png)


既然我们可以方便的在相册之间切换了，那么我们就能方便的给相册添加照片。

比如我先在一个照片中选上想要的照片，然后直接把选中的照片按住，拖到左边的相册处，再松手，就ok了！！相当方便。

如果你想拖到的相册屏幕中显示不了，没事，拖动照片到左边底部区域，这时左边的相册的table就会向下滚动，如果到了你想要的相册，再移出底部就可以了（如果移动到顶部，就会向上滚）。


![image](https://github.com/peterchen145/swallow/raw/master/imgs/selectImg1.png)

![image](https://github.com/peterchen145/swallow/raw/master/imgs/selectImg2.png)




--------------分割线----------------------

接下来想做的功能：

分享，预览。


希望大家多多支持！！
