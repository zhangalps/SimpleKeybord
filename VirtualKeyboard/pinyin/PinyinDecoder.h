#pragma once

#include <QString>
#include <QStringList>
#include <QVector>
#include <QHash>
#include <QReadWriteLock>
#include <memory>

namespace ime_pinyin {

struct PhraseEntry {
    QString text;           // 汉字或词组，例如 "工控"
    QString fullPinyin;     // 完整无空格拼音，例如 "gongkong"
    QStringList syllables;  // 音节数组，例如 ["gong", "kong"]
    QString initials;       // 声母简拼，例如 "gk"
    int frequency = 100;    // 词频权重
};

struct SearchResult {
    QString segmentedPinyin;     // 分词后的展示拼音，如 "gong'kong"
    QString composedPrefix;      // 分步造词已选定的前缀汉字
    QString remainingPinyin;     // 剩余待匹配的拼音
    QStringList candidates;      // 排序后的候选词列表
    QVector<int> consumedLengths;// 每个候选词对应的原始拼音消耗长度
};

class PinyinDecoder
{
public:
    PinyinDecoder();
    ~PinyinDecoder();

    // 在后台线程加载内置词库与可选的外部词库文件
    bool loadDictionary(const QString &customDictPath = QString());
    bool isLoaded() const;
    size_t memoryUsageBytes() const;

    // 执行拼音分词与候选词检索
    SearchResult search(const QString &rawPinyin) const;

    // splitPinyinToSyllables 将连续拼音切分为标准音节序列
    QStringList splitSyllables(const QString &pinyin) const;

    // 动态提升用户高频选词权重
    void boostCandidate(const QString &word);

private:
    bool isValidSyllable(const QString &syl) const;
    bool isValidPrefix(const QString &prefix) const;
    QString extractInitials(const QStringList &syllables) const;

    mutable QReadWriteLock m_lock;
    bool m_loaded = false;
    size_t m_memoryBytes = 0;

    // 标准汉语拼音音节集合（含声母缩写）
    QHash<QString, QString> m_singleCharMap; // syllable -> 按字频排列的单字集合
    QVector<PhraseEntry> m_phrases;          // 词组词库
    QHash<QString, QVector<int>> m_FirstCharIndex; // 首字母加速索引
    QHash<QString, int> m_userBoost;         // 用户选词动态提权
};

} // namespace ime_pinyin

