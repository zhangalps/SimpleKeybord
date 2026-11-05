#include "PinyinDecoder.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStringConverter>
#include <QTextStream>
#include <algorithm>
#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace ime_pinyin {

static const QStringList kStandardSyllables = {
    "a", "ai", "an", "ang", "ao",
    "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao", "bie", "bin", "bing", "bo", "bu",
    "ca", "cai", "can", "cang", "cao", "ce", "cen", "ceng", "cha", "chai", "chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong", "chou", "chu", "chua", "chuai", "chuan", "chuang", "chui", "chun", "chuo", "ci", "cong", "cou", "cu", "cuan", "cui", "cun", "cuo",
    "da", "dai", "dan", "dang", "dao", "de", "dei", "den", "deng", "di", "dia", "dian", "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo",
    "e", "ei", "en", "eng", "er",
    "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu",
    "ga", "gai", "gan", "gang", "gao", "ge", "gei", "gen", "geng", "gong", "gou", "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo",
    "ha", "hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hong", "hou", "hu", "hua", "huai", "huan", "huang", "hui", "hun", "huo",
    "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju", "juan", "jue", "jun",
    "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou", "ku", "kua", "kuai", "kuan", "kuang", "kui", "kun", "kuo",
    "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian", "liang", "liao", "lie", "lin", "ling", "liu", "lo", "long", "lou", "lu", "lv", "luan", "lue", "lun", "luo",
    "ma", "mai", "man", "mang", "mao", "me", "mei", "men", "meng", "mi", "mian", "miao", "mie", "min", "ming", "miu", "mo", "mou", "mu",
    "na", "nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ni", "nian", "niang", "niao", "nie", "nin", "ning", "niu", "nong", "nou", "nu", "nv", "nuan", "nue", "nuo",
    "o", "ou",
    "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng", "pi", "pian", "piao", "pie", "pin", "ping", "po", "pou", "pu",
    "qi", "qia", "qian", "qiang", "qiao", "qie", "qin", "qing", "qiong", "qiu", "qu", "quan", "que", "qun",
    "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou", "ru", "rua", "ruan", "rui", "run", "ruo",
    "sa", "sai", "san", "sang", "sao", "se", "sen", "seng", "sha", "shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi", "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui", "shun", "shuo", "si", "song", "sou", "su", "suan", "sui", "sun", "suo",
    "ta", "tai", "tan", "tang", "tao", "te", "teng", "ti", "tian", "tiao", "tie", "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo",
    "wa", "wai", "wan", "wang", "wei", "wen", "weng", "wo", "wu",
    "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu", "xu", "xuan", "xue", "xun",
    "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yo", "yong", "you", "yu", "yuan", "yue", "yun",
    "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zha", "zhai", "zhan", "zhang", "zhao", "zhe", "zhei", "zhen", "zheng", "zhi", "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo", "zi", "zong", "zou", "zu", "zuan", "zui", "zun", "zuo"
};

static QString stripToneMarks(const QString &input)
{
    QString out;
    out.reserve(input.size());
    for (QChar c : input) {
        const ushort u = c.unicode();
        switch (u) {
        // a tones: \u0101 \u00e1 \u01ce \u00e0 \u0251
        case 0x0101: case 0x00e1: case 0x01ce: case 0x00e0: case 0x0251:
            out.append(u'a');
            break;
        // e tones: \u0113 \u00e9 \u011b \u00e8 \u00ea
        case 0x0113: case 0x00e9: case 0x011b: case 0x00e8: case 0x00ea:
            out.append(u'e');
            break;
        // i tones: \u012b \u00ed \u01d0 \u00ec
        case 0x012b: case 0x00ed: case 0x01d0: case 0x00ec:
            out.append(u'i');
            break;
        // o tones: \u014d \u00f3 \u01d2 \u00f2
        case 0x014d: case 0x00f3: case 0x01d2: case 0x00f2:
            out.append(u'o');
            break;
        // u tones: \u016b \u00fa \u01d4 \u00f9
        case 0x016b: case 0x00fa: case 0x01d4: case 0x00f9:
            out.append(u'u');
            break;
        // v (u-umlaut) tones: \u00fc \u01d6 \u01d8 \u01da \u01dc
        case 0x00fc: case 0x01d6: case 0x01d8: case 0x01da: case 0x01dc:
            out.append(u'v');
            break;
        // nasal n/m tones: \u0144 \u0148 \u01f9 \u1e3f
        case 0x0144: case 0x0148: case 0x01f9:
            out.append(u'n');
            break;
        case 0x1e3f:
            out.append(u'm');
            break;
        default:
            if ((u >= u'a' && u <= u'z') || (u >= u'A' && u <= u'Z')) {
                out.append(c.toLower());
            }
            break;
        }
    }
    return out;
}

PinyinDecoder::PinyinDecoder() = default;
PinyinDecoder::~PinyinDecoder() = default;

bool PinyinDecoder::loadDictionary(const QString &customDictPath)
{
    QWriteLocker locker(&m_lock);
    m_singleCharMap.clear();
    m_phrases.clear();
    m_FirstCharIndex.clear();
    m_memoryBytes = 0;

    QStringList candidatePaths;
    if (!customDictPath.isEmpty()) {
        candidatePaths << customDictPath;
    }
    candidatePaths << QStringLiteral(":/qt/qml/VirtualKeyboard/pinyin.txt")
                   << QStringLiteral(":/VirtualKeyboard/pinyin.txt")
                   << QCoreApplication::applicationDirPath() + QStringLiteral("/pinyin.txt")
                   << QDir::currentPath() + QStringLiteral("/VirtualKeyboard/pinyin.txt")
                   << QStringLiteral("E:/projects/qt_projects/SimpleKeyborad/VirtualKeyboard/pinyin.txt");

    QFile file;
    for (const QString &p : candidatePaths) {
        if (QFileInfo::exists(p)) {
            file.setFileName(p);
            if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                break;
            }
        }
    }

    if (!file.isOpen()) {
        return false;
    }

    // Separate buckets by GB2312 Level-1 (3755 everyday chars), Level-2, and Rare CJK
    QHash<QString, QString> tier1Primary;   // GB2312 Level-1 primary reading
    QHash<QString, QString> tier1Secondary; // GB2312 Level-1 polyphone secondary reading
    QHash<QString, QString> tier2Chars;     // GB2312 Level-2
    QHash<QString, QString> rareChars;      // Other BMP CJK

    auto classifyCharTier = [](const QString &ch) -> int {
#ifdef Q_OS_WIN
        if (ch.length() == 1) {
            const wchar_t wc = ch.at(0).unicode();
            unsigned char buf[4] = {0};
            int bytes = WideCharToMultiByte(936, 0, &wc, 1, reinterpret_cast<LPSTR>(buf), sizeof(buf), nullptr, nullptr);
            if (bytes == 2) {
                const unsigned char b1 = buf[0];
                const unsigned char b2 = buf[1];
                if (b1 >= 0xB0 && b1 <= 0xD7 && b2 >= 0xA1 && b2 <= 0xFE)
                    return 1; // GB2312 Level-1 (3755 most common Chinese characters)
                if (b1 >= 0xD8 && b1 <= 0xF7 && b2 >= 0xA1 && b2 <= 0xFE)
                    return 2; // GB2312 Level-2
            }
        }
#endif
        return 3;
    };

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);

    while (!in.atEnd()) {
        const QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(u'#'))
            continue;

        // Parse format: U+4E2D: zh\u014dng,zh\u00f2ng  # \u4e2d
        if (line.startsWith(QStringLiteral("U+"))) {
            const int colonIdx = line.indexOf(u':');
            if (colonIdx <= 2)
                continue;

            bool ok = false;
            const uint codePoint = line.mid(2, colonIdx - 2).trimmed().toUInt(&ok, 16);
            if (!ok || codePoint == 0)
                continue;

            const bool isCommonBMP = (codePoint >= 0x4E00 && codePoint <= 0x9FA5);
            const bool isRareBMP = (codePoint >= 0x3400 && codePoint < 0x4E00) || (codePoint > 0x9FA5 && codePoint <= 0x9FFF);
            if (!isCommonBMP && !isRareBMP && codePoint != 0x3007)
                continue;

            int hashIdx = line.indexOf(u'#', colonIdx + 1);
            const QString pinyinPart = (hashIdx > colonIdx)
                                           ? line.mid(colonIdx + 1, hashIdx - colonIdx - 1).trimmed()
                                           : line.mid(colonIdx + 1).trimmed();

            const QString chStr = QString::fromUcs4(reinterpret_cast<const char32_t *>(&codePoint), 1);
            const int tier = isCommonBMP ? classifyCharTier(chStr) : 3;
            const QStringList rawSyls = pinyinPart.split(u',', Qt::SkipEmptyParts);

            QStringList addedSyls;
            for (int i = 0; i < rawSyls.size(); ++i) {
                const QString plain = stripToneMarks(rawSyls.at(i).trimmed());
                if (plain.isEmpty() || addedSyls.contains(plain))
                    continue;
                addedSyls.append(plain);

                auto addToBucket = [&](const QString &sylKey) {
                    if (tier == 1) {
                        if (i == 0) tier1Primary[sylKey].append(chStr);
                        else tier1Secondary[sylKey].append(chStr);
                    } else if (tier == 2) {
                        tier2Chars[sylKey].append(chStr);
                    } else {
                        rareChars[sylKey].append(chStr);
                    }
                };

                addToBucket(plain);
                if (plain == QStringLiteral("lve")) {
                    addToBucket(QStringLiteral("lue"));
                } else if (plain == QStringLiteral("nve")) {
                    addToBucket(QStringLiteral("nue"));
                }
            }
        }
    }

    QStringList allSylKeys = tier1Primary.keys();
    for (const QString &k : tier1Secondary.keys()) if (!allSylKeys.contains(k)) allSylKeys.append(k);
    for (const QString &k : tier2Chars.keys()) if (!allSylKeys.contains(k)) allSylKeys.append(k);
    for (const QString &k : rareChars.keys()) if (!allSylKeys.contains(k)) allSylKeys.append(k);

    for (const QString &k : allSylKeys) {
        const QString combined = tier1Primary.value(k) + tier1Secondary.value(k) + tier2Chars.value(k) + rareChars.value(k);
        m_singleCharMap.insert(k, combined);
        m_memoryBytes += (k.size() + combined.size()) * sizeof(QChar);
    }

    m_loaded = !m_singleCharMap.isEmpty();
    return m_loaded;
}

bool PinyinDecoder::isLoaded() const
{
    QReadLocker locker(&m_lock);
    return m_loaded;
}

size_t PinyinDecoder::memoryUsageBytes() const
{
    QReadLocker locker(&m_lock);
    return m_memoryBytes;
}

bool PinyinDecoder::isValidSyllable(const QString &syl) const
{
    return kStandardSyllables.contains(syl);
}

bool PinyinDecoder::isValidPrefix(const QString &prefix) const
{
    for (const QString &s : kStandardSyllables) {
        if (s.startsWith(prefix))
            return true;
    }
    return false;
}

QString PinyinDecoder::extractInitials(const QStringList &syllables) const
{
    QString res;
    for (const QString &s : syllables) {
        if (!s.isEmpty())
            res.append(s.at(0));
    }
    return res;
}

QStringList PinyinDecoder::splitSyllables(const QString &pinyin) const
{
    QStringList result;
    const QString clean = pinyin.toLower().trimmed();
    int pos = 0;
    const int len = clean.length();

    while (pos < len) {
        if (clean.at(pos) == u'\'') {
            ++pos;
            continue;
        }
        int matchedLen = 0;
        const int maxTry = std::min(6, len - pos);
        for (int l = maxTry; l >= 1; --l) {
            const QString sub = clean.mid(pos, l);
            if (isValidSyllable(sub)) {
                if (pos + l < len) {
                    const QChar nextCh = clean.at(pos + l);
                    const bool nextIsVowel = (nextCh == u'a' || nextCh == u'e' || nextCh == u'o' || nextCh == u'i' || nextCh == u'u' || nextCh == u'v');
                    if (nextIsVowel && l > 1 && !isValidPrefix(clean.mid(pos + l, std::min(2, len - pos - l)))) {
                        if (isValidSyllable(clean.mid(pos, l - 1))) {
                            matchedLen = l - 1;
                            break;
                        }
                    }
                }
                matchedLen = l;
                break;
            }
        }

        if (matchedLen == 0) {
            for (int l = maxTry; l >= 1; --l) {
                if (isValidPrefix(clean.mid(pos, l))) {
                    matchedLen = l;
                    break;
                }
            }
        }
        if (matchedLen == 0)
            matchedLen = 1;

        result.append(clean.mid(pos, matchedLen));
        pos += matchedLen;
    }
    return result;
}

SearchResult PinyinDecoder::search(const QString &rawPinyin) const
{
    SearchResult out;
    const QString query = rawPinyin.toLower().remove(u'\'').trimmed();
    if (query.isEmpty())
        return out;

    QReadLocker locker(&m_lock);

    const QStringList syllables = splitSyllables(query);
    out.segmentedPinyin = syllables.join(u'\'');

    const QString firstSyl = syllables.first();
    const int firstSylLen = firstSyl.length();

    QHash<QString, bool> seen;

    auto appendCharsWithBoost = [&](const QString &chars, int consumedLen) {
        QVector<QPair<int, QString>> boosted;
        QStringList normal;
        for (const QChar &ch : chars) {
            const QString s(ch);
            if (seen.contains(s))
                continue;
            seen.insert(s, true);
            const int b = m_userBoost.value(s, 0);
            if (b > 0) {
                boosted.append({b, s});
            } else {
                normal.append(s);
            }
        }
        std::sort(boosted.begin(), boosted.end(), [](const auto &a, const auto &b) {
            return a.first > b.first;
        });
        for (const auto &pair : boosted) {
            out.candidates.append(pair.second);
            out.consumedLengths.append(consumedLen);
        }
        for (const QString &s : normal) {
            out.candidates.append(s);
            out.consumedLengths.append(consumedLen);
        }
    };

    if (m_singleCharMap.contains(firstSyl)) {
        appendCharsWithBoost(m_singleCharMap.value(firstSyl), firstSylLen);
    } else {
        // Prefix match when user has typed an incomplete syllable (e.g. "zh", "sh", "g")
        for (const QString &stdSyl : kStandardSyllables) {
            if (stdSyl.startsWith(firstSyl) && m_singleCharMap.contains(stdSyl)) {
                appendCharsWithBoost(m_singleCharMap.value(stdSyl).left(12), firstSylLen);
            }
        }
    }

    return out;
}

void PinyinDecoder::boostCandidate(const QString &word)
{
    if (word.isEmpty())
        return;
    QWriteLocker locker(&m_lock);
    m_userBoost[word] = m_userBoost.value(word, 0) + 1;
}

} // namespace ime_pinyin
